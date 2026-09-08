#!/bin/bash
steamcmd +login anonymous +app_update {{ game_id }} validate +quit
cd {{ game_working_directory }}
{{ game_exec_start }}
