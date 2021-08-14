defmodule Nightwatch.Helpers.Records do

  @spec via_tuple(any) :: {:via, Registry, {Nightwatch.GameRegistry, any}}
  def via_tuple(process_name) do
    {:via, Registry, {Nightwatch.GameRegistry, process_name}}
  end

  @spec is_process_registered(any) :: [{pid, any}]
  def is_process_registered(process_name) do
    Registry.lookup(Nightwatch.GameRegistry, process_name)
  end
end
