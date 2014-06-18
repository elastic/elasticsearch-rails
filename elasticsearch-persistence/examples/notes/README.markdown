Demo Aplication for the Repository Pattern
==========================================

This directory contains a simple demo application for the repository pattern of the `Elasticsearch::Persistence`
module in the [Sinatra](http://www.sinatrarb.com) framework.

To run the application, first install the required gems and start the application:

```
bundle install
bundle exec ruby application.rb
```

The application demonstrates:

* How to use a plain old Ruby object (PORO) as the domain model
* How to set up, configure and use the repository instance
* How to use the repository in tests

## License

This software is licensed under the Apache 2 license, quoted below.

    Copyright (c) 2014 Elasticsearch <http://www.elasticsearch.org>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
