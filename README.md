# JrmvnRunner

If you are looking for the easy way to run your JRuby application and to indicate the gem and jar dependencies in a
single place, this library might be one of the acceptable options for you. Please take a look at the alternatives
first, like [JBundler](https://github.com/mkristian/jbundler) and [Doubleshot](https://github.com/sam/doubleshot).
Jrmvnrunner simply creates the temporary Gemfile and pom.xml for your project according to your setup and then
invokes bundle install and mvn install accordingly. This is very simple and transparent approach to collect all the
required dependencies specified in a single file.

## Why?

Doubleshot looks ok, but it requires java 1.7+. JBundler is good, but sometimes does not do what you want.

## What it gives

You can create the Jrmvnrunner file at the root level of your project with the following content:

```ruby

project 'mygroup:myproject:0.1'

Pomfile do
    source 'http://maven.smecsia.me'
    jar 'commons-lang:commons-lang:2.6:jar'
end

Gemfile do
    source :rubygems
    gem 'json'
    gem 'rspec', '~> 2.12.0'
    gem 'rake', '10.0.3'
    gem 'activesupport', '~> 3.2.8'
    gem 'activerecord', '~> 3.2.8'
    gem 'cucumber'
end

```

Then you can execute:

```
jrmvnrun exec rake features
```

This will execute a command with the full jar dependencies list in the classpath,
so you can use them inside your ruby code.

## How to install

```
jruby -S gem install jrmvnrunner
```

## Requirements

Jrmvnrunner requires JDK 1.6+, Maven 3+, Jruby 1.7+ installed. It will look at your PATH for mvn, jruby,
jgem and bundle executables.