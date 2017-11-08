# Thank you for contributing.  This is a placeholder document while we develop our contribution guidelines.



*Ignore all below this line*

==========================================================

# How to become a contributor and submit your own code

## Contributor License Agreements

We'd love to accept your patches! Before we can take them, we
have to jump a couple of legal hurdles.

Please fill out either the individual or corporate Contributor License Agreement
(CLA).

  * If you are an individual writing original source code and you're sure you
    own the intellectual property, then you'll need to sign an 
    [individual CLA](https://developers.google.com/open-source/cla/individual).
  * If you work for a company that wants to allow you to contribute your work,
    then you'll need to sign a 
    [corporate CLA](https://developers.google.com/open-source/cla/corporate).

Follow either of the two links above to access the appropriate CLA and
instructions for how to sign and return it. Once we receive it, we'll be able to
accept your pull requests.

## Contributing A Patch

1. Submit an issue describing your proposed change to the repo in question.
1. The repo owner will respond to your issue promptly.
1. If your proposed change is accepted, and you haven't already done so, sign a
   Contributor License Agreement (see details above).
1. Fork the desired repo, develop and test your code changes.
1. Ensure that your code adheres to the existing style in the sample to which
   you are contributing. Refer to the 
   [Google Cloud Platform Samples Style Guide](https://github.com/GoogleCloudPlatform/Template/wiki/style.html) for the recommended coding standards for this organization.
1. Ensure that your code has an appropriate set of unit tests which all pass.
1. Submit a pull request.


==========================================================

# Contributing

Thank you for your interest in [PROJECT NAME]! 

The Islandora project, including Islandora Labs, operates under the Islandora [code of conduct]. 
By participating in this project, you agree to abide by its terms. 
Please report inappropriate behaviour to community@islandora.ca.

[code of conduct]: http://islandora.ca/codeofconduct

## Communication

Islandora, and Islandora Labs, invites community discussion on the following channels. If you are not sure you want to create an issue or pull request yet, feel free to discuss this project with us here:
* the IRC channel, #islandora, on freenode.net
* our [Google Group/mailing list], 
* our bi-weekly committers' calls, on Skype and open to everybody (contact community@islandora.ca to join)
* our various [Interest Groups]

[Google Group/mailing list]: https://groups.google.com/forum/#!forum/islandora
[Interest Groups]: https://github.com/islandora-interest-groups

## Contributions

To request a feature, report a bug, or suggest improvements to documentation for this repository:
* create an issue using the Github Issues tool
* if you would also like to contribute a fix, then create a pull request referencing that issue. 

Anyone with a github account may create an issue, but there are some constraints (see below) on who may contribute pull requests.

## Constraints on merging 

As with all projects in Islandora Labs, all contributors to a pull request must have an Islandora 
CLA ([Contributor License Agreement]) on file before it can be merged. 
Here, a contributor is defined as the author of a git commit.

In Islandora Labs, the policies for merging may be different from the standard [Islandora Committer's Workflow]. 
These policies are set at the discretion of the Current Maintainer, as defined in this project's README.md.

In this project, the following policies apply:
* Only maintainers of this module may merge pull requests.
* A person may *not* merge their own pull requests, nor a pull request that they have contributed code to.
* A formal review (using Github's Review feature) is *not* required.
* A pull request may be merged at any time after it is created.
* A person *may* merge code contributed by another employee of the same organization.

[Islandora Labs Committers Group]: https://github.com/orgs/Islandora-Labs/teams/committers/members
[Contributor License Agreement]: https://github.com/Islandora/islandora/blob/7.x/CONTRIBUTING.md#contribute-code
[Islandora Committer's Workflow]: https://github.com/Islandora/islandora/wiki/Islandora-Committers-Workflow



==========================================================

# How to contribute

I like to encourage you to contribute to the repository.
This should be as easy as possible for you but there are a few things to consider when contributing.
The following guidelines for contribution should be followed if you want to submit a pull request.

## How to prepare

* You need a [GitHub account](https://github.com/signup/free)
* Submit an [issue ticket](https://github.com/anselmh/CONTRIBUTING.md/issues) for your issue if there is no one yet.
	* Describe the issue and include steps to reproduce if it's a bug.
	* Ensure to mention the earliest version that you know is affected.
* If you are able and want to fix this, fork the repository on GitHub

## Make Changes

* In your forked repository, create a topic branch for your upcoming patch. (e.g. `feature--autoplay` or `bugfix--ios-crash`)
	* Usually this is based on the master branch.
	* Create a branch based on master; `git branch
	fix/master/my_contribution master` then checkout the new branch with `git
	checkout fix/master/my_contribution`.  Please avoid working directly on the `master` branch.
* Make sure you stick to the coding style that is used already.
* Make use of the `.editorconfig`-file if provided with the repository.
* Make commits of logical units and describe them properly.
* Check for unnecessary whitespace with `git diff --check` before committing.

* If possible, submit tests to your patch / new feature so it can be tested easily.
* Assure nothing is broken by running all the tests.

## Submit Changes

* Push your changes to a topic branch in your fork of the repository.
* Open a pull request to the original repository and choose the right original branch you want to patch.
	_Advanced users may install the `hub` gem and use the [`hub pull-request` command](https://hub.github.com/hub.1.html)._
* If not done in commit messages (which you really should do) please reference and update your issue with the code changes. But _please do not close the issue yourself_.
_Notice: You can [turn your previously filed issues into a pull-request here](http://issue2pr.herokuapp.com/)._
* Even if you have write access to the repository, do not directly push or merge pull-requests. Let another team member review your pull request and approve.

# Additional Resources

* [General GitHub documentation](http://help.github.com/)
* [GitHub pull request documentation](https://help.github.com/articles/about-pull-requests/)
* [Read the Issue Guidelines by @necolas](https://github.com/necolas/issue-guidelines/blob/master/CONTRIBUTING.md) for more details

