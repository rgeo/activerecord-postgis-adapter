### 7.0.1 / 2021-01-13

* Fix db:gis:setup task #329
### 7.0.0 / 2020-12-22

* Add ActiveRecord 6.1 Compatability (tagliala) #324
* Change SpatialFactoryStore attribute parsing #325
* Update Arel Module #325

### 6.0.1 / 2020-08-16

* Fix SchemaStatements#initialize_type_map #309
* Add support for Ruby 2.7 #306
* Adapt gem to ActiveRecord 6.0. #315

### 6.0.0 / 2019-08-21

* Support ActiveRecord 6.0 #303

### 5.2.2 / 2018-12-02

* Freeze strings

### 5.2.1 / 2018-03-05

* Fix type parsing for Z/M variants with no SRID #281, #282
* Test ActiveRecord 5.2 with pg gem version 1.0.0 #279

### 5.2.0 / 2017-12-24

* Support comments - #275

---
* Note: rgeo 2.0 is supported with version 5.1.0+
* The rgeo gem version requirement is specified by rgeo-activerecord
---

### 5.1.0 / 2017-12-02

* Require rgeo-activerecord 6.0, require rgeo 1.0. #272

### 5.0.3 / 2017-11-09

* Improve requires, fix warnings #268
* Improve readme #264
* Fix Travis #261
* Remove comment #260
* Fix regex for parsing spacial column types #259

### 5.0.2 / 2017-06-14

* Use PG::Connection instead of PGconn #257

### 5.0.1 / 2017-05-01

* Fix activerecord gem dependency - 69e8815

### 5.0.0 / 2017-05-01 *** YANKED

* Support ActiveRecord 5.1 - #246

### 4.1.2 / 2018-03-05

* Fix type parsing for Z/M variants with no SRID #283

### 4.1.1 / 2017-12-24

* Support comments - backport #275

### 4.1.0 / 2017-12-02

* Require rgeo-activerecord 6.0, require rgeo 1.0.

### 4.0.5 / 2017-11-09

* Backport fixes from master #270
* Fix circular require warning
* Improve requires
* Fix regex for parsing spacial column types #259

### 4.0.4 / 2017-06-14

* Use PG::Connection instead of PGconn #257

### 4.0.3 / 2017-04-30

* Fix st_point, st_polygon exports (affects schema.rb) #253, #226

### 4.0.2 / 2016-11-13

* Revert #237

### 4.0.1 / 2016-11-08 *** YANKED

* Auto-load tasks (#237)

### 4.0.0 / 2016-06-30

* Support ActiveRecord 5.0 (#213)
* Fix schema dump null issues in JRuby (#229)

### 3.1.5 / 2017-04-30

* Fix st_point, st_polygon exports (affects schema.rb) #252, #226

### 3.1.4 / 2016-02-07

* Ignore PostGIS views on schema dump - #208

### 3.1.3 / 2016-01-15

* Restrict ActiveRecord support to 4.2. See 649707cdf

### 3.1.2 / 2015-12-29

* Require rgeo-activerecord 4.0.4

### 3.1.1 / 2015-12-28

* Fix require for rgeo-activerecord 4.0.2
* Rubocop-related cleanup #203

### 3.1.0 / 2015-11-19

* Add JRuby support (#199)

### 3.0.0 / 2015-05-25

* Support & require ActiveRecord 4.2 (#145)
* Require rgeo-activerecord 4.0 (#180, 089d2dedd9b)
* Rename adapter module from PostGISAdapter to PostGIS (c2fa909bb)
* Breaking change: remove #set_rgeo_factory_settings
* Breaking change: remove #rgeo_factory_for_column
* Breaking change: remove #has_spatial_constraints?

### 2.2.1 / 2014-09-22

* Update gemspec to not allow update to ActiveRecord 4.2, as it does not work.

### 2.2.0 / 2014-08-11

* Add JRuby support
  (https://github.com/rgeo/activerecord-postgis-adapter/pull/102)

### 2.1.1 / 2014-06-17

* Correct behavior of non-geographic null: false columns
  (https://github.com/rgeo/activerecord-postgis-adapter/pull/127)
* Loosen rgeo-activerecord dependency

### 2.1.0 / 2014-06-11

* Add a separate SpatialColumnInfo class to query spatial column info
  (https://github.com/rgeo/activerecord-postgis-adapter/pull/125)
* Update column migration method to correctly set null: false
  (https://github.com/rgeo/activerecord-postgis-adapter/pull/121)

### 2.0.2 / 2014-06-06

* Fix add_index for referenced columns (regression)
  (https://github.com/rgeo/activerecord-postgis-adapter/issues/60)
* Remove unused no_constraints option handling from add_column
  (https://github.com/rgeo/activerecord-postgis-adapter/pull/117)
* Use ActiveSupport::TestCase for base test class
* Remove unused script_dir setting


### 2.0.1 / 2014-05-16

* Fix sql index dump for non-spatial columns
  (https://github.com/rgeo/activerecord-postgis-adapter/issues/92)


### 2.0.0 / 2014-05-15

* Bump Major version bump because the location of the railtie.rb file has
  moved and some methods were removed.
* Remove special handling for the "postgis" schema (see
  https://github.com/rgeo/activerecord-postgis-adapter/pull/114)
* Consolidate the railtie files
* Remove internal rails4/ and shared/ directories


### 1.1.0 / 2014-05-07

* Relax the ActiveRecord version requirement to support both 4.0.x and 4.1.x
  in a single gem.
* The 0.7.x versions and 0.7-stable branch are now obsolete.


### 0.6.6 / 2014-05-07

* Backport: Only create extension "if not exists"
* Fix ActiveRecord 3.1 compatibility with activerecord-jdbc-adapter


### 1.0.0 / 2014-05-06

* Require rgeo-activerecord 1.0.0
* Require ActiveRecord 4.1


### 0.7.1 / 2014-05-06 << obsolete (use 1.x)

* Updates for the Rails 4.0.x-compatible adapater can be found on the
  0.7-stable branch
* Require rgeo-activerecord 0.6.0, which includes bug fixes for Rails 4.0.x


### 0.7.0 / 2014-05-06 << obsolete (use 1.x)

* Version 0.7.0 is for Rails 4.0.x
* Require ruby 1.9.3+
* Require ActiveRecord 4.0
* Drop JRuby support (temporary)


### 0.6.5 / 2013-06-24

* Fixed syntax errors in rake db:gis:setup task. (Pull requests by rhodrid
  and jdurand)


### 0.6.4 / 2013-05-28

* Fixed a crash with array conversions in Rails 4. (Contributed by
  Christopher Bull)
* The gis setup task was broken in any Rails other than 3.2.x. Fixed (I
  think). (Reports by Rupert de Guzman and slbug)
* Raise a more useful exception for the (as yet) unsupported combination of
  Rails 4 and JRuby.


### 0.6.3 / 2013-05-04

* Several fixes for compatibility with changes to Rails 4.0.0 rc1. (Reports
  by slbug and Victor Costan)
* Rails 3 rake tasks properly set PGUSER when appropriate. (Pull request by
  Mitin Pavel)
* Fixed a nil exception on some Rails 4 migrations. (Pull request by
  ivanfoong and Victor Costan)


### 0.6.2 / 2013-03-08

* The PostGIS setup now properly connects as the superuser. (Reported by
  Adam Trilling)
* Fix database setup rake tasks under jruby/jdbc adapter. (Pull request by
  Nick Muerdter)
* Drop table no longer tries to modify the geometry_columns view under
  PostGIS 2.0.
* The Rakefile is now compatible with RubyGems 2.0.


### 0.6.1 / 2013-02-28

* Fixed some gem loading issues.


### 0.6.0 / 2013-02-28

* Experimental support for the recently released Rails 4.0 beta.
* Documentation improvements.


### 0.5.1 / 2013-02-04

* Database creation properly treats geometry_columns as a view when setting
  owner. (Pull request by hendrikstier)
* Provide rake db:gis:setup task. (Pull request by Cody Russell)
* Modifications for compatibility with postgres_ext. (Pull request by
  legendetm)
* SpatialTableDefinition properly subclasses the Postgres-specific table
  definition class, if available. (Pull request by Joe Noon)
* Database creation script no longer fails if the username includes weird
  characters. (Contributed by Toms Mikoss)
* Updates for compatibility with jdbc-postgres 9.2.1002.1


### 0.5.0 / 2012-12-12

Thanks to the many who have submitted pull requests. A bunch of them are in
this release. Special thanks to Nick Muerdter, who succeeded in porting the
adapter to work with the JDBC Postgres adapter in JRuby, and also got Travis
up and running for the project.

* Add JRuby compatibility with the activerecord-jdbcpostgresql-adapter gem.
  (Pull request by Nick Muerdter)
* Allow WKT to be to be specified as a string-like object rather than having
  to be a String. (Pull request by Bryan Larsen)
* Ignore postgis_topology tables 'layer' and 'topology' in rake
  db:schema:dump. (Pull request by Greg Phillips)
* Create schemas specified in schema_search_path only if they don't exist.
  (Pull request by legendetm)
* Force the postgis_topology extension be created in the topology schema.
  (Pull request by Dimitri Roche)
* Specifically set the ownership of the postgis related tables to the
  regular user. (Pull request by corneverbruggen)
* The gemspec no longer includes the timestamp in the version, so that
  bundler can pull from github. (Reported by corneverbruggen)
* Update tests for PostGIS 2.0 compatibility.
* Travis-CI integration. (Pull request by Nick Muerdter)
* Add a missing srid in the Readme. (Pull request by gouthamvel)
* Readme clarifies that BoundingBox objects can be used in a query only for
  projected coordinate systems. (Reported by Tee Parham)
* Update URLs to point to new website.


### 0.4.3 / 2012-04-13

* Rake tasks failed on Rails 3.0.x because of an issue with
  rgeo-activerecord pre-0.4.5. Now we require the fixed version.


### 0.4.2 / 2012-04-12

* Support the db:structure:load rake task in recent versions of Rails.
* Support installing PostGIS via the PostgreSQL extension mechanism
  (requires at least PostGIS 2.0 and PostgreSQL 9.1).
* Support bounding boxes in queries (useful for "window" queries such as
  finding objects to display in a map region).
* Fix some issues determine the correct default value for spatial columns.


### 0.4.1 / 2012-02-22

* Some compatibility fixes for Rails 3.2. (Reported by Ryan Williams with
  implementation help from Radek Paviensky.)
* Now requires rgeo-activerecord 0.4.3.


### 0.4.0 / 2011-08-15

* Various fixes for Rails 3.1 compatibility.
* Now requires rgeo-activerecord 0.4.0.
* INCOMPATIBLE CHANGE: simple queries (e.g. MyClass.where(:latlon =>
  my_point)) use an objective rather than spatial equality test. Earlier
  versions transformed this form to use st_equals, but now if you need to
  test for spatial equality, you'll need to call st_equals explicitly. I'm
  still evaluating which direction we want to go with this in the future,
  but we may be stuck with the current behavior because the hack required to
  transform these queries to use spatial equality was egregious and broke in
  Rails 3.1 with no clear workaround.


### 0.3.6 / 2011-06-21

* Require latest rgeo-activerecord to get some fixes.
* Note PostgreSQL 9 requirement in the README. (Reported by Samuel Cochran)
* Now doesn't throw exceptions if an RGeo cast fails when setting an
  attribute.


### 0.3.5 / 2011-04-12

* The .gemspec was missing the databases.rake file. Fixed.


### 0.3.4 / 2011-04-11

* A .gemspec file is now available for gem building and bundler git
  integration.


### 0.3.3 / 2011-02-28

* INCOMPATIBLE CHANGE: the default SRID for non-geography columns is now -1,
  rather than 4326. (Geography columns still default to 4326.)
* It is now possible to create a spatial column without a corresponding
  entry in the geometry_columns table, and the adapter now handles this case
  properly. (Reported by Pirmin Kalberer)
* Now requires rgeo-activerecord 0.3.1 (which brings a critical fix
  involving declaring multiple spatial columns in a migration).


### 0.3.2 / 2011-02-11

* You can now specify a separate "database creation" superuser role so your
  normal PostgreSQL login role doesn't need superuser privileges when
  running database creation tasks.
* Database creation tasks automatically create all schemas listed in the
  schema search path.


### 0.3.1 / 2011-02-01

* Fixed a syntax error that prevented the adapter from loading on Ruby 1.8.
  Whoops. (Reported by miguelperez)


### 0.3.0 / 2011-01-26

* Reworked type and constraint handling, which should result in a large
  number of bug fixes, especially related to schema dumps.
* Experimental support for complex spatial queries. (Requires Arel 2.1,
  which is expected to be released with Rails 3.1.)
* The path to the Railtie is now different (see the README), though a
  compatibility wrapper has been left in the old location.
* Getting index information from the ActiveRecord class now properly
  recognizes spatial-ness.
* Reorganized the code a bit for better clarity.


### 0.2.3 / 2011-01-06

* Many of ActiveRecord's rake tasks weren't working because they need to
  know about every adapter explicitly. I hesitate to call this "fixed" since
  I see it as a problem in ActiveRecord, but we now at least have a
  workaround so the rake tasks will run properly. (Reported by Tad Thorley.)
* Dumping schema.rb now omits the PostGIS internal tables.
* Added a new configuration parameter pointing to the script directory, for
  rake db:create.
* If the "postgis" schema is included in the schema search path, it is used
  as a container for the PostGIS internal definitions when running rake
  db:create. Furthermore, that schema is omitted when dumping the
  structure.sql. This should eliminate all the PostGIS internal cruft from
  SQL structure dumps, and also eliminate the errors that would appear when
  rebuilding a test database because the PostGIS internals would get applied
  twice.


### 0.2.2 / 2010-12-27

* Support for basic spatial equality queries. e.g. constructs such as:
    MyClass.where(:geom_column => factory.point(1, 2))
    MyClass.where(:geom_column => 'POINT(1 2)')

* Fixed an exception when adding spatial columns where the column name is
  specified as a symbol.


### 0.2.1 / 2010-12-15

* Provides meta-information to RGeo 0.2.2 or later to support access to
  PostGIS's spatial reference system table.


### 0.2.0 / 2010-12-07

* Initial public alpha release. Spun activerecord-postgis-adapter off from
  the core rgeo gem.
* You can now set the factory for a specific column by name.


For earlier history, see the History file for the rgeo gem.
