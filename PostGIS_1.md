# PostGIS 1.5 Notes

The latest version of `activerecord-postgis-adapter` requires PostGIS 2.0+.
These notes apply only to PostGIS 1.5.
If you are using PostGIS 1.5, use version 0.6.x of the adapter and read this section.

Gemfile:

```ruby
gem 'activerecord-postgis-adapter', '~> 0.6.6'
```

### PostGIS 1.5 Install Notes

### `database.yml`

##### Creating the PostGIS extension

*If you have an older PostgreSQL or an older PostGIS* you will not be able to
run the SQL command `create extension postgis` to install PostGIS into your database. In
this case, instead of including `postgis_extension`, you should include
`script_dir` in the `database.yml` configuration. This should be set to a directory
containing two files that contain all the PostGIS-provided spatial
definitions: `postgis.sql` and `spatial_ref_sys.sql`.

This directory is usually in the share/contrib directory of your PostgreSQL
installation. To find it, run

```sh
pg_config --sharedir
```

Then, append `contrib`, and look for a subdirectory named "postgis-(version)".
For example, if you installed PostgreSQL in /usr/local, and you are running
PostGIS 1.5, you should probably set `script_dir` to
`/usr/local/share/contrib/postgis-1.5`.

*If you are using a template to install PostGIS into your database* then set
the `template` configuration as appropriate, and *omit* both the
`postgis_extension` and `script_dir` configurations. In this case, you also do
not need to include `su_username` or `su_password`, since those configurations
apply only to adding the extension or using the script dir.

*If you do not want the spatial declarations to live in a separate schema*
then do *not* include "postgis" on the `schema_search_path`. Note that we
recommend separating PostGIS into a separate schema, because that is the best
way to ensure `rake test` works properly and is able to create the test
database.

###### `schema_search_path`

If you include a schema called "postgis" in the search path, the adapter will isolate all the
PostGIS-specific definitions, including data types, functions, views, and so
forth, into that schema instead of including them in the default "public"
schema. Then, when Rails needs to dump the schema (for example, to replicate
it for the test database), it can use that isolation to omit the PostGIS
definitions from cluttering the schema dump.

The credentials that your app will use to connect to the database should be
given in the `username` and `password` fields. Generally, for security
reasons, it is not a good idea for this user to have "superuser" privileges.
However, the adapter *does* need superuser privileges for one function:
installing PostGIS into the database when the database is first created.
Therefore, you should provide a *second* set of credentials, `su_username` and
`su_password`, which identify a superuser account. This account will be used
once, when you create the database (i.e. rake db:create), and not afterward.

### Schema Dump and Reload

The presence of geospatial data in a database causes some issues with
ActiveRecord's schema dump and restore functions. This is because (1)
installing PostGIS into your database injects a lot of objects in your
database that can clutter up schema dumps, and (2) to define a spatial column
correctly, you generally must call a SQL function such as AddGeometryColumn(),
and Rails's schema dumper isn't smart enough to reproduce those function
calls.

Because of this, we recommend the following:

*   Install the PostGIS definitions in a separate schema called "postgis" (as
    described in the recommended installation procedure above). The
    activerecord-postgis-adapter will ignore a schema called "postgis" when
    dumping the schema, thus omitting the clutter.

*   Set the ActiveRecord schema format to `:ruby`, *not* `:sql`. The former
    emits higher level commands that can be interpreted correctly to reproduce
    the schema. The latter, however, emits low level SQL, which loses
    information such as the fact that AddGeometryColumn() was originally used
    to generate a column. Executing a `:sql` format schema dump will *not*
    correctly reproduce the schema.


Of course, the above discussion is really relevant only if you are using the
ActiveRecord rake tasks that create and restore databases, either directly
such as `rake db:create` or indirectly such as `rake test`. It does not have
any effect on running migrations or normal website execution.
