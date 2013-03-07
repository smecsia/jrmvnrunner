# JRMVNRunner

If you are looking for the easy way to run your JRuby application and to indicate the jar dependencies in a single
place, this library might be one of the acceptable variants for you. Please take a look at the analogues first,
like [JBundler](https://github.com/mkristian/jbundler) and [Doubleshot](https://github.com/sam/doubleshot).

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