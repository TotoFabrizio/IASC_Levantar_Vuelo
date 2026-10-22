defmodule RelaxedProcessesSpawner do
  @doc """
    Module for generating workers that will be using the HordeSupervisor and Registry
  """
  use Task
  require Logger

  alias CustomIASC.{HordeSupervisor}
  alias IascHordeExample.{SleepProcess}

  @doc """
    Function to spawn n SleepProcess that will after some seconds, generate a random number
  """
  def start_link_create(number, ttl) do
    Task.start_link(__MODULE__, :create_process, [number, ttl])
  end

  def start_link_stress_them(number) do
    Task.start_link(__MODULE__, :stress_them, [number])
  end

  def start_link_stop(number) do
    Task.start_link(__MODULE__, :stop, [number])
  end

  def stress_them(number) do
    for x <- 0..number do 
      pid = SleepProcess.whereis_identifier(x)
      if pid do
        send(pid, :stress)
      end
    end
  end

  def stop(number) do
    for x <- 0..number do 
      pid = SleepProcess.whereis_identifier(x)
      if pid do
        send(pid, :terminate)
      end
    end
  end

  def create_process(process_number, ttl) do
    for number <- 0..process_number do 
      child_spec = SleepProcess.child_spec(number, seconds_with_jitter(ttl))
      HordeSupervisor.start_child(child_spec)
  
      Logger.info("started process #{number}")
    end
  end

  defp seconds_with_jitter(ttl) do
    (ttl * 0.55 + :rand.uniform(ttl) / 2)
    |> round()
  end
end

# RelaxedProcessesSpawner.start_link_create(20,12)
# RelaxedProcessesSpawner.start_link_stop(20)