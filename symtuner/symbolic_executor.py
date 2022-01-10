'''Symbolic executor interface

This module defines an interface for symbolic executor.
'''

from abc import ABC
from abc import abstractmethod


class SymbolicExecutor(ABC):
    '''Abstract class for all classes that wrap symbolic executors

    All symbolic executors that for SymTuner *must* inherit this class and implement the
    `SymbolicExecutor.run` method and `SymbolicExecutor.get_time_prameter`.
    '''

    @abstractmethod
    def run(self, target, parameters, **kwargs):
        '''Run symbolic executor with the given parameters and return a list of generated testcases

        This method will make a command and run a symbolic executor internally and collect the
        generated testcases with the given parameters.

        Args:
            target: A target program to run with symbolic executor.
            parameters: Key-value pairs for the symbolic executor. Set value as None for
                the on-off option.
            kwargs: Any keyword arguments that are needed to run symbolic executor.

        Returns:
            A list of all generated testcases with the given paramets.
        '''

    @abstractmethod
    def get_time_parameter(self):
        '''Return a parameter to set the time budget

        This method will return a name of the paremter to set the time budget of symbolic executor.

        Returns:
            A name of parameter to set the time budger.
        '''
