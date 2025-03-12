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
use warehouse AUDIO_WH_S;

-- Create compute pool for GPU processing
create compute pool if not exists GPU_POOL
  MIN_NODES = 1
  MAX_NODES = 5
  INSTANCE_FAMILY = GPU_NV_M;

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
  directory = (enable = true)
  URL = 's3://sfquickstarts/sfguide_getting_started_with_audio_sentiment_analysis_using_snowflake_notebooks';

grant all on stage AUDIO_FILES to role AUDIO_CONTAINER_RUNTIME_ROLE;  -- First, create an internal stage to store the files

-- First, create an internal stage to store the files
CREATE OR REPLACE STAGE INTERNAL_AUDIO_FILES
    DIRECTORY = (ENABLE = TRUE)
    encryption = (type = 'SNOWFLAKE_SSE');

-- Copy files from the external stage to the internal stage
COPY FILES
  INTO @INTERNAL_AUDIO_FILES
  FROM @AUDIO_FILES;

grant all on stage INTERNAL_AUDIO_FILES to role AUDIO_CONTAINER_RUNTIME_ROLE;  