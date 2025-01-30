-- Set role to ACCOUNTADMIN for setup
use role ACCOUNTADMIN;

-- Create database and schema
create database if not exists AUDIO_SENTIMENT_DB;
create schema if not exists AUDIO_SCHEMA;

-- Create warehouse
create warehouse if not exists AUDIO_WH_S WAREHOUSE_SIZE=SMALL;

-- Set context
use database AUDIO_SENTIMENT_DB;
use schema AUDIO_SCHEMA;
use warehouse AUDIO_WH_S;p

-- Create compute pool for GPU processing
create compute pool if not exists GPU_POOL
  MIN_NODES = 1
  MAX_NODES = 5
  INSTANCE_FAMILY = GPU_NV_L;

-- Create role for container runtime
create role if not exists AUDIO_CONTAINER_RUNTIME_ROLE;
grant role AUDIO_CONTAINER_RUNTIME_ROLE to role ACCOUNTADMIN;

-- Grant necessary privileges
grant usage on database AUDIO_SENTIMENT_DB to role AUDIO_CONTAINER_RUNTIME_ROLE;
grant all on schema AUDIO_SCHEMA to role AUDIO_CONTAINER_RUNTIME_ROLE;
grant usage on warehouse AUDIO_WH_S to role AUDIO_CONTAINER_RUNTIME_ROLE;
grant all on compute pool GPU_POOL to role AUDIO_CONTAINER_RUNTIME_ROLE;

-- Create network rule for external access
create network rule if not exists allow_all_rule
  TYPE = 'HOST_PORT'
  MODE = 'EGRESS'
  VALUE_LIST = ('0.0.0.0:443', '0.0.0.0:80');

-- Create external access integration
create external access integration if not exists allow_all_access_integration
  ALLOWED_NETWORK_RULES = (allow_all_rule)
  ENABLED = true;

grant usage on integration allow_all_access_integration to role AUDIO_CONTAINER_RUNTIME_ROLE;

-- Create stages for audio files
create stage if not exists AUDIO_FILES
  encryption = (type = 'SNOWFLAKE_SSE')
  directory = (enable = true);

grant all on stage AUDIO_FILES to role AUDIO_CONTAINER_RUNTIME_ROLE;