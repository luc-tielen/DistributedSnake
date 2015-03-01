-module(gpio).
-export([pin_mode/2, pin_release/1, 
         digital_write/2, digital_read/1]).

%% Module that exposes an Arduino-like API for controlling the GPIO pins
%% of the Raspberry Pi.



%% READING INPUT
%% _____________
%%
%%typical test/usage, testing
%%
%% RespBerryPi 2: Pin-numbering
%% ______________________
%% |                1  2 |
%% |                3  4 |
%% |                5  5 |
%% |                7  8 |
%% |               .. .. |
%% |                     |
%% |               41 42 |
%% |                     |
%% |                     |
%% |                     |
%% |                     |
%% |  ___    ___   ___   |
%% | |eth|  |USB| |USB|  |
%% ______________________
%%
%%
%%  Pin 1  = 3.3V
%%  Pin 6  = Ground
%%  Pin 12 = I/O 18
%%
%%
%% electic scheme:
%% Pin 1 ___ R ____/ __ Pin 6
%%               |
%%             Pin 12
%%
%%
%% test from command-prompt:
%% > cd DistributedSnake/src
%% > sudo erl
%% > c(gpio.erl).
%% > gpio:pin_mode(18, input).
%% > gpio:digital_read(18).




%% WRITING OUTPUT
%% ______________
%%
%%typical test/usage, testing
%%
%% RespBerryPi 2: Pin-numbering
%% ______________________
%% |                1  2 |
%% |                3  4 |
%% |                5  5 |
%% |                7  8 |
%% |               .. .. |
%% |                     |
%% |               41 42 |
%% |                     |
%% |                     |
%% |                     |
%% |                     |
%% |  ___    ___   ___   |
%% | |eth|  |USB| |USB|  |
%% ______________________
%%
%%  Pin 6  = Ground
%%  Pin 12 = I/O 18
%%
%%
%% electic scheme:
%% Pin 12 ___ R __ LED __ Pin 6
%%
%%
%% test from command-prompt:
%% > cd DistributedSnake/src
%% > sudo erl
%% > c(gpio.erl).
%% > gpio:pin_mode(18, output).
%% > gpio:digital_write(18, high).
%% > gpio:digital_write(18, low).


%% API:

%% Registers the pin as input or output.
pin_mode(Pin, output) when Pin > 0 ->
    pin_export(Pin),
    File = pin_direction_path(Pin),
    write_to_file(File, "out"),
    %%io:format("gpio pin_mode output ~w ~n",[Pin]),   
    digital_write(Pin, low);    %% Avoid side-effects: output goes high on startup
pin_mode(Pin, input) when Pin > 0 ->
    pin_export(Pin),
    File = pin_direction_path(Pin),
    write_to_file(File, "in").

%% Unregisters the pin as input or output.
pin_release(Pin) when Pin > 0 ->
    File = "/sys/class/gpio/unexport",
    Contents = integer_to_list(Pin),
    write_to_file(File, Contents).

%% Writes a value to a certain pin.
digital_write(Pin, high) when Pin > 0 ->
    File = pin_value_path(Pin),
    write_to_file(File, "1");
digital_write(Pin, low) when Pin > 0 ->
    File = pin_value_path(Pin),
    write_to_file(File, "0").

%% Reads a value from a certain pin.
digital_read(Pin) when Pin > 0 ->
    File = pin_value_path(Pin),
    Contents = read_from_file(File, 1),
    digital_read(contents, Contents).


digital_read(contents, {ok, <<48>>}) -> low;
digital_read(contents, {ok, <<49>>}) -> high.

%% Helper functions:

%% Helper function to export a pin as input or output.
pin_export(Pin) ->
    File = "/sys/class/gpio/export",
    Contents = integer_to_list(Pin),
    write_to_file(File, Contents).

%% Helper function to retrieve the path to the file to control the direction 
%% of a GPIO pin.
pin_direction_path(Pin) -> 
    Path = pin_path(Pin),
    lists:flatten([Path, "/direction"]).

%% Helper function to retrieve the path to the file to read/write a value
%% from/to the GPIO pin.
pin_value_path(Pin) -> 
    Path = pin_path(Pin),
    lists:flatten([Path, "/value"]).

%% Helper function that generates the path to a file based on pin number.
pin_path(Pin) ->
    lists:flatten(["/sys/class/gpio/gpio", integer_to_list(Pin)]).

%% Helper function to write to a file.
write_to_file(FilePath, Contents) when is_list(FilePath) 
                                  andalso is_list(Contents) ->
    Options = [write, binary],
    {ok, File} = file:open(FilePath, Options),
    file:write(File, Contents),
    file:close(File).

%% Reads a certain amount of bytes from a file.
read_from_file(FilePath, Length) when is_list(FilePath) andalso Length > 0 ->
    Options = [read, binary],
    {ok, File} = file:open(FilePath, Options),
    {ok, Contents} = file:read(File, Length),
    file:close(File),
    Contents.
