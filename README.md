# acoustofluidic-control-langmuir

This repository contains the code used in the experiments for the paper:

Kyriacos Yiannacou and Veikko Sariola, "Controlled Manipulation and Active
Sorting of Particles Inside Microfluidic Chips Using Bulk Acoustic Waves and
Machine Learning"

The code was written and tested in Matlab 2019a&b.

Probably the most interesting part of the repository is the script
[src/bandit_ctrl.m](src/bandit_ctrl.m), which contains the implementation of our
e-greedy and UCB1 control algorithms.

Also [src/+experiments/](src/+experiments/) is of interest, as it contains basic
scripts to run the single-particle and multi-particle manipulation experiments.

To test the code, run `runtests tests`.
