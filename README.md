# MyopicVicar

MyopicVicar is an open-source genealogical 🧬 record database and search engine.  It is the 
software that powers the [FreeREG](https://www.freereg.org.uk) database of parish register 
entries and the [FreeCEN](https://www.freecen.org.uk) database of UK census records.

The tool has been developed by [Free UK Genealogy](https://www.freeukgenealogy.org.uk/), a 
registered charity dedicated to making genealogical information freely available online.
It is released under the Apache 2.0 license.

## Initial Setup

To simplify local setup, you can use our Docker configuration to run the application in a container. Download Docker Desktop [here](https://www.docker.com/products/docker-desktop/).

Once you have Docker Desktop installed, **_ensure it is running_**, then follow these steps to get the application up and running locally.

#### Clone the repo
```
git clone git@github.com:FreeUKGen/MyopicVicar.git
```
#### cd into the root directory
```
cd MyopicVicar
```
#### Add config files
The following config files are required to run the application.  You can find examples of these files in the `config/` directory.  

Reach out to the project maintainers ([via email](info@freeukgenealogy.org.uk), or Slack) for the correct values to use in your environment.
```
config/application.yml
config/database.yml
config/errbit.config.yml
config/secrets.yml
config/mongoid.yml
config/mongo_config.yml
config/freeukgen_application.yml
```
#### Build and run the docker image
```
docker-compose build
docker-compose up
```
#### Run database migrations
```
docker-compose run --rm app rails db:migrate
```
#### Seed the database
```
docker-compose run --rm app rails db:seed
```

#### Precompile assets
```
docker-compose run --rm app rails assets:precompile
```

Following the initial setup, you can simply run `docker-compose up` to start the application.

## We Need You! 🧬 🧑‍💻
Volunteers are essential to every part of the project. We welcome contributions to the 
software, documentation, and to the records themselves.

Getting involved with helping out is simple; have a go at something on our waffle boards with a ‘Good First Issue’ label. Visit <a href="https://www.freeukgenealogy.org.uk/about/volunteer/tech-volunteering-opportunities/good-first-issue-volunteer">our 'GFI' web page</a> for more information.

See [CONTRIBUTING.md](CONTRIBUTING.md) for more details on ways to contribute. 


## Architecture

Myopic Vicar uses MongoDB to allow researchers to search heterogeneous records.  Both FreeREG and FreeCEN projects accept volunteer contributions as spreadsheets, while metadata, quality control and coordination provided by volunteer coordinators and data managers.   



Please see <a href="https://docs.google.com/document/d/11n5F9WB9WA9BgZwj1QDJf2OdZOPO1-jkdY1cXOU-AHE/edit#heading=h.acid0fo1ifql">Installation Instructions</a> (outdated instructions, for reference only) for more information.

## Release Notes 

* FreeREG - [master/doc/release_notes](https://github.com/FreeUKGen/MyopicVicar/tree/master/doc/release_notes)
* FreeCEN - [freecen_parsing/doc/release_notes](https://github.com/FreeUKGen/MyopicVicar/tree/freecen_parsing/doc/release_notes)


## TODO

Improvements still to do for local setup:-

* Fix `RecordType.all_types + [nil]` nil error when no seed data
* Add command to seed the mongo db with data