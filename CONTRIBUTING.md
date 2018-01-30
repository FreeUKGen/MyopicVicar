# Thank you for contributing.  This is a placeholder document while we develop our contribution guidelines.

Thank you for your interest in Free UK Genealogy and the MyopicVicar 
genealogical records database and search engine!

# Get Started

Please begin by filling in our new tech volunteer form and letting us know a bit about you. We will also use this to add you to our Slack community.

https://docs.google.com/forms/d/1QX4-Cw5-d4ipZVZ4uvl2QPcCvnA5Sm0Aj-IWJhP7igA/

Ensure you let us know what idea you might like to help develop, or indeed if you have a new idea you would like to discuss. We will update the ideas as often as possible, however it is always a good idea to check them out on Github too (see below for instructions).

If you are interested in Google’s Summer of Code, please read and apply here: https://summerofcode.withgoogle.com/get-started/.

## Our Code of Conduct

Free UK Genealogy, including its software development team, operates 
under a [code of 
conduct](https://www.freeukgenealogy.org.uk/files/Documents/Code-of-Conduct.pdf).

The short version is, _Be excellent to each other_.  (See the full version at 
https://www.freeukgenealogy.org.uk/files/Documents/Code-of-Conduct.pdf)

## How We Develop Software

Free UK Genealogy development operates on a modified Agile methodology, 
working in two-week sprints.  Technical teams developing MyopicVicar and 
related tools meet via a Google Hangout videoconference every two on 
Wednesday at 1530 GMT/1030 EST (FreeCEN) or 1630 GMT/1130 EST (FreeREG).  
Participants in this meeting review the previous sprint's work, discuss 
blocked issues, and schedule work for the next sprint.  Attendance at 
these meetings is not mandatory, but an email update from developers 
unable to attend is appreciated.

All development is tracked in Github issues, and organized and 
prioritized using Waffle.io, which provides a kanban-style interface.

* The [FreeREG Waffle Board](https://waffle.io/freeukgen/myopicvicar)
* The [FreeCEN Waffle Board](https://waffle.io/freeukgen/freecenmigration)



## How We Communicate

The Free UK Genealogy development team communicates through several channels.  

* A traditional mailing list allows developers and system administrators 
to discuss production issues and large-scale architectural changes.
* A [Slack team](https://freeukgenealogy.slack.com) provides more immediate communication among developers on 
different projects and supports occasional asynchronous discussion.
* Google Hangouts allow video and live-chat meetings.

In addition, several projects have Google Groups for discussion among 
volunteers transcribing records.

## How You Can Contribute

There are many ways to contribute to Free UK Genealogy projects without 
developing a line of software.

### Transcribing Records

Each project needs volunteers to help transcribe records.  In addition 
to benefiting the needs of the projects, this provides a deep 
introduction to the project aims and the perspective of our users.

[Learn more about transcribing](https://www.freeukgenealogy.org.uk/about/volunteer/transcriber-volunteering-opportunities/)

### Product Research and Testing

Frequently, user-reported issues need specific reproduction steps and 
suggestions of correct behavior.  Attempting to reproduce, document, and 
define these issues is a valuable contribution to the project and also a 
great way to learn about the details of the tools and their users.

One way to find these bugs is to go to the waffle boards listed above and look for the "Good First Issue" label.

### Code

Projects also need developers to contribute code, whether that be bug 
fixes, data analysis, or new and improved features.

_We highly recommend that volunteer developers contact our volunteer coordinator [denise.colbert@freeukgenealogy.org.uk](mailto:denise.colbert@freeukgenealogy.org.uk) to be 
partnered with a mentor.  This mentor can help answer questions and 
smooth over difficulties faced by people new to the codebase._

While some developers install a full Ruby on Rails/MongoDB/MySQL stack 
on their development machines, the easiest way to get up and running is 
to develop code in a virtual workspace provided by Cloud9.

[See instructions for getting set up on Cloud9](https://docs.google.com/document/d/1OWbya7erLmyyFstMwuBJwkquJZG4i4YrMWIHHI4Jvjk/edit#heading=h.r8mtsch418p2)


## Contributing A Patch

1. Ask your mentor (or another member of the technical team) to add you as a contributor to the repository.
1. Create a branch for your change off of `master` or (for FreeCEN-specific features) `freecen_parsing`
1. Develop and test your changes locally.
1. Push your changes to Github.
1. Create a pull request to merge your branch into `master` (or `freecen_parsing`).
1. Assign the pull request to your mentor to review and merge.


