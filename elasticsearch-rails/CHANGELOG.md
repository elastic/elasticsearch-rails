## 0.1.9

* Added checks for proper launch order and other updates to the example application templates
* Updated the example application to work with Elasticsearch 2.x
* Used the `suggest` method instead of `response['suggest']` in the application template

## 0.1.8

* Added an example application template that loads settings from a file
* Added missing require in the seeds.rb file for the expert template
* Fixed double include of the aliased method (execute_without_instrumentation)
* Fixed the error when getting the search_controller_test.rb asset in `03-expert.rb` template
* Updated URLs for getting raw assets from Github in the `03-expert.rb` template

## 0.1.7

* Updated dependencies for the gem and example applications
* Fixed various small errors in the `01-basic.rb` template
* Fixed error when inserting the Kaminari gem into Gemfile in the 02-pretty.rb template
* Fixed incorrect regex for adding Rails instrumentation into the application.rb in the `02-pretty.rb` template
* Fixed other small errors in the `02-pretty.rb` template
* Improved and added tests for the generated application from the `02-pretty.rb` template
* Added the `04-dsl.rb` template which uses the `elasticsearch-dsl` gem to build the search definition

## 0.1.6

* Fixed errors in templates for the Rails example applications
* Fixed errors in the importing Rake task
* Refactored and updated the instrumentation support to allow integration with `Persistence::Model`

## 0.1.5

* Fixed an exception when no suggestions were returned in the `03-expert` example application template

## 0.1.2

* Allow passing an ActiveRecord scope to the importing Rake task

## 0.1.1

* Improved the Rake tasks
* Improved the example application templates

## 0.1.0 (Initial Version)
