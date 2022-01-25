'''Common components for SymTuner

This module contains common componets for SymTuner. This module includes time budget hander
and SymTuner interface (with implementation of common algorithm).
'''

from abc import ABC
from abc import abstractclassmethod
from abc import abstractmethod
from copy import deepcopy
from datetime import datetime
from pathlib import Path
import json
import numpy as np
import random

from symtuner.logger import get_logger


class TimeBudgetHandler:
    '''Time budget handler class

    Time budget handler class. This will help user to set gradually increasing time budget.
    '''

    def __init__(self, total_budget,
                 minimum_ratio=0.005,
                 steps_per_round=20,
                 increase_ratio=2.,
                 minimum_time_budget=30):
        '''Create a time budget hander

        Create a time budget handler. This handles time as seconds.

        Args:
            total_budget: Total amount of seconds.
            minimum_ratio: Minimum time budget ratio. The first time budget will be set as the
                product of `total_budget` and `minimum_ratio`. Note that, the minimum budget
                adjusted if it is smaller than 1. By default, this will be set as 0.005.
            steps_per_round: Number of steps before increasing time budget. By default, this will
                be set as 20.
            increase_ratio: The multiple used when calculating next time budget. The next time
                budget after `steps_per_round` will caculated as the product of latest time
                budget and `increase_ratio`. By default, this will be set as 2.
        '''

        self.total_budget = total_budget
        self.steps_per_round = steps_per_round
        self.increase_ratio = increase_ratio

        self.steps_in_round = 0
        self.current_time_budget = int(self.total_budget * minimum_ratio)
        self.current_time_budget = max(self.current_time_budget,
                                       minimum_time_budget)

        self.start_time: datetime = datetime.now()

    def get_time_budget(self):
        '''Get time budget for this iteration

        Calcuate and returns a time budget for this iteration

        Returns:
            Time budget in seconds. If time budget expired return -1.
        '''

        # Check timeout
        time_elapsed = (datetime.now() - self.start_time).total_seconds()
        if time_elapsed > self.total_budget:
            return -1

        # Get next time step
        self.steps_in_round += 1
        if self.steps_in_round > self.steps_per_round:
            self.current_time_budget *= self.increase_ratio
            self.current_time_budget = int(self.current_time_budget)
            self.steps_in_round = 1
        remaining_time = self.total_budget - int(time_elapsed)
        time_budget = min(self.current_time_budget, remaining_time)
        return time_budget

    def __iter__(self):
        '''Magic method to make iterable

        Magic method to make iterable.

        Yields:
            Time budget calculated with `TimeBudgetHander.get_time_budget` method.

        Raises:
            StopIteration: When time budget expried.
        '''

        while True:
            time_budget = self.get_time_budget()
            if time_budget < 0:
                break
            yield time_budget
        return

    @property
    def elapsed(self):
        '''Calculate elapsed time in seconds

        Calculae elapsed time in seconds. Note that this is a property, not a method.

        Returns:
            Elapsed time in seconds.
        '''

        return int((datetime.now() - self.start_time).total_seconds())


class SymTuner(ABC):
    '''SymTuner interface with common algorithm implemented

    SymTUner interface with common algorirhm implemented. Symbolic executor specific SymTuner
    needs 2 abstract methods to be re-implemented: `SymTuner.evaluate` and
    `SymTuner.get_default_space`.
    '''

    def __init__(self, parameter_space=None, exploit_portion=0.7):
        '''Create SymTuner

        Create SymTuner.

        Args:
            parameter_space: A dictionary with tuning space and default parameters are defined.
                Tuning space should be defined with 'space' key, and default parameters should be
                defined with 'defaults' key. If not specified, use the defaults spaces defined
                following methods: `SymTuner.get_default_space` and
                `SymTuner.get_default_default_parameters`.
            exploit_portion: A portion of exploit. By default, this will be set as 0.7.
        '''

        if parameter_space is None:
            self.space = self.get_default_space()
            self.defaults = self.get_default_default_parameters()
            get_logger().info('Parameter space not defined. Default space are loaded.')

        else:
            if isinstance(parameter_space, str):
                parameter_space = Path(parameter_space)
            if isinstance(parameter_space, Path):
                parameter_space_filename = parameter_space
                parameter_space = json.loads(parameter_space.read_text())
                get_logger().info('Parameter space loaded from a file: '
                                  f'{parameter_space_filename}')
            self.space = parameter_space['space']
            self.defaults = parameter_space['defaults']

        self.cnts = {}
        self.len_cnts = {}
        for param, (space, n_sample) in self.space.items():
            self.cnts[param] = {}
            for val in space:
                self.cnts[param][val] = 0
            self.len_cnts[param] = {}
            for i in range(1, n_sample + 1):
                self.len_cnts[param][i] = 0

        self.exploit_portion = exploit_portion

        self.data = []

    def count_used_parameters(self, parameters):
        '''Update count of used parameters

        Update how many times that parameters are used. Only consider if parameter is in tuning
        space.

        Args:
            parameters: A dictionary of used parameters.
        '''

        for param, values in parameters.items():
            if param not in self.space.keys():
                continue
            self.len_cnts[param][len(values)] += 1
            for value in values:
                self.cnts[param][value] += 1

    def sample(self, policy=None):
        '''Sample a set of parameters to use

        Sampling with 2 policies: exploit and eplore.

        Args:
            policy: Sampling policy. One of 'exploit' and 'explore'. If not set, sampling with
            [exploit_portion, 1 - exploit_portion] internally.

        Returns:
            A dictionary of sampled parameters.
        '''

        if policy is None:
            policy = random.choices(['exploit', 'explore'],
                                    [self.exploit_portion, 1 - self.exploit_portion])[0]
        policy_fn = getattr(self, policy)
        parameters = self.defaults.copy()
        prob_dict = policy_fn(self.data)
        sampled = {}
        for param, (space, n_sample) in self.space.items():
            if len(space) == 0:
                continue
            prob, n_prob = prob_dict[param]
            n_sample = list(range(1, n_sample + 1))
            n_sample = random.choices(n_sample, n_prob)[0]
            sampled[param] = random.choices(space, prob, k=n_sample)
        parameters.update(sampled)
        return parameters

    def normalize(self, a_list):
        '''Returns a normalized list

        Normalize the given list of numbers. After normalization the sum of all elemens becomes 1.
        If all elements of the given list are 0, returns a uniform list that the sum of it is 1.

        Args:
            a_list: A list of numbers.

        Returns:
            A normalized list of the given list.
        '''

        if np.sum(a_list) == 0:
            a_list = [1 for _ in a_list]
        a_list = a_list / np.sum(a_list)
        return a_list

    def explore(self, data):
        '''Return the probability of explore policy

        Return the probability of explore policy.

        Args:
            data: A list of quadruples of coverage, found bugs, a testcase, and used parameters.

        Returns:
            A dictionary of the probability of each parameter space. Key is the name of the
            parameter and the value is a tuple of probability of each element in the space and
            probability about how many times to sample.
        '''

        prob_dict = {}
        for param in self.space.keys():

            prob = []
            for value in self.space[param][0]:
                if value in self.cnts[param].keys() and self.cnts[param][value] > 0:
                    p = 1.0 / self.cnts[param][value]
                    p = round(p, 2)
                else:
                    p = 10
                prob.append(p)

            n_prob = []
            for n in range(1, self.space[param][1] + 1):
                if self.len_cnts[param][n] > 0:
                    p = 1.0 / self.len_cnts[param][n]
                    p = round(p, 2)
                else:
                    p = 10
                n_prob.append(p)

            prob = self.normalize(prob)
            n_prob = self.normalize(n_prob)
            prob_dict[param] = (prob, n_prob)
        return prob_dict

    def exploit(self, data):
        '''Return the probability of exploit policy

        Return the probability of exploit policy.

        Args:
            data: A list of quadruples of coverage, found bugs, a testcase, and used parameters.

        Returns:
            A dictionary of the probability of each parameter space. Key is the name of the
            parameter and the value is a tuple of probability of each element in the space and
            probability about how many times to sample.
        '''

        # Extract core parameters used
        core_parameters = self.extract_core_parameters(data)

        core_cnts = {}
        core_len_cnts = {}
        for param, (_, n_sample) in self.space.items():
            core_cnts[param] = {}
            # Not using space because some space can be updated
            cnt_keys = self.cnts[param].keys()
            for val in cnt_keys:
                core_cnts[param][val] = 0
            core_len_cnts[param] = {}
            for i in range(1, n_sample + 1):
                core_len_cnts[param][i] = 0

        for parameter in core_parameters:
            for param, values in parameter.items():
                if param not in self.space.keys():
                    continue
                core_len_cnts[param][len(values)] += 1
                for value in values:
                    core_cnts[param][value] += 1

        prob_dict = {}
        for param in self.space.keys():

            prob = []
            for value in self.space[param][0]:
                if value in core_cnts[param].keys() \
                        and value in self.cnts[param].keys() and self.cnts[param][value] > 0:
                    p = core_cnts[param][value] / self.cnts[param][value]
                    p = round(p, 2)
                elif value not in self.cnts[param].keys() or self.cnts[param][value] == 0:
                    p = 10
                else:
                    p = 0
                prob.append(p)

            n_prob = []
            for n in range(1, self.space[param][1] + 1):
                if self.len_cnts[param][n] > 0:
                    p = core_len_cnts[param][n] / self.len_cnts[param][n]
                    p = round(p, 2)
                else:
                    p = 0
                n_prob.append(p)

            prob = self.normalize(prob)
            n_prob = self.normalize(n_prob)
            prob_dict[param] = (prob, n_prob)
        return prob_dict

    def extract_core_parameters(self, data):
        '''Extract core results in data

        Find out the smallest set of parameters that covers all the covered coverage and all found
        bugs.

        Args:
            data: A list of quadruples of coverage, found bugs, a testcase, and used parameters.

        Returns:
            A list of core parameters that covers all coverages and bugs.
        '''

        # Return variable
        core_paramters = []

        # Get total coverage
        total_coverage = set()
        for cov, _, _, _ in data:
            total_coverage = total_coverage | cov

        # Find good testcases
        accumulated_coverage = set()
        copied_data = deepcopy(data)

        while True:
            if len(copied_data) == 0:
                break
            copied_data = sorted(copied_data,
                                 key=lambda elem: len(elem[0]),
                                 reverse=True)
            top_cov, _, _, param = copied_data.pop(0)
            if len(top_cov) > 0:
                accumulated_coverage = accumulated_coverage | top_cov
                copied_data = [(cov - accumulated_coverage, bug, tc, param)
                               for cov, bug, tc, param in copied_data]
                core_paramters.append(param)
            else:
                break

        # Find bug finding testcases
        found_bugs = []
        for _, bugs, _, param in data[::-1]:
            for bug in bugs:
                if bug not in found_bugs:
                    found_bugs.append(bug)
                    core_paramters.append(param)

        return core_paramters

    def add(self, target, parameters, testcases, evaluation_kwargs=None):
        '''Evaluate and update data

        Evaluate and update data.

        Args:
            target: A target program to evaluate with.
            paramters: A set of parameters used to generated testcases.
            testcases: Testcases genereted with parameters.
            evaluation_kwargs: A dictionary of keyword arguments pass to evaluate method.

        Returns:
            Self object for chaining. All updates is recorded in the object.
        '''

        if evaluation_kwargs is None:
            evaluation_kwargs = {}

        self.count_used_parameters(parameters)
        for testcase in testcases:
            coverage, bug = self.evaluate(target, testcase,
                                          **evaluation_kwargs)
            self.data.append((coverage, bug, testcase, parameters))
        return self

    def get_space_json(self):
        '''Get tuning space and default parameters

        Get tuning space and default parameters.

        Returns:
            A dictionary of tuning space and default parameters.
        '''

        json_dict = {
            'space': self.space,
            'defaults': self.defaults,
        }
        return json_dict

    def get_coverage_and_bugs(self):
        '''Get total coverage and bugs

        Get total coverage and bugs collected.

        Returns:
            A tuple of coverage and bugs found in total. The first element of the tuple is a set
            of coverage and the second element is a set of bugs.
        '''

        coverage = set()
        bugs = set()
        for cov, bug, _, _ in self.data:
            coverage = coverage | cov
            bugs = bugs | bug
        return coverage, bugs

    def get_testcase_causing_bug(self, bug):
        '''Get testcase causing the given bug

        Get testcase causing the given bug. If there are multiple testcases, return the latest one.

        Args:
            bug: A bug interested in.

        Returns:
            A latest testcase causes the given bug. Returns None if no testcase is found.
        '''

        for _, bugs, tc, _ in self.data[::-1]:
            if bug in bugs:
                return tc
        return None

    @abstractmethod
    def evaluate(self, target, testcase, **kwargs):
        '''Evaluate the given testcase

        Evaluate the given testcase and report the coverage (i.e. branch coverage) and a bug
        if found. This part should be written for each symbolic executor to handle the testcases
        generated in different format.

        Args:
            testcase: A testcase to evaluate.

        Returns:
            A tuple of bugs if found and the coverage (i.e. branch coverage). If bug are not found,
            the first element of the return tuple will be an empty set.
        '''

    @abstractclassmethod
    def get_default_space(cls):
        '''Make a default parameter space

        Make a default parameter space. This part should be written for each symbolic executor.

        Returns:
            A dictionary whose keys are the name of the parameters and values are the possible
            space for each parameter.
        '''

    @classmethod
    def get_default_default_parameters(cls):
        '''Make a default default parameter set

        Make a default default parameter set. The parameters included in this set always will be
        sampled. This part may be written for each symbolic executor. By default, the return value
        is an empty list.

        Returns:
            A dictionary of parameters that should be included in every symbolic executor calls.
        '''

        return {}

    @classmethod
    def get_default_space_json(cls):
        '''Get default tuning space and default default parameters

        Get default tuning space and default default parameters.

        Returns:
            A dictionary of tuning space and default parameters.
        '''

        json_dict = {
            'space': cls.get_default_space(),
            'defaults': cls.get_default_default_parameters(),
        }
        return json_dict
