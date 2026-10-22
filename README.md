# IascHordeExample

**Small example using Horde**

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `iasc_elixir_horde_minimal_example` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:iasc_elixir_horde_minimal_example, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/iasc_elixir_horde_minimal_example>.

## How to start it?

Just run the following command:

```bash
iex -sname node1 --cookie some_cookie -S mix
```

this will start the cluster, with just one cluster member, if you want to add more nodes, just add them with a sname, and using the same cookie you set to the first node, otherwise, the nodes won't be able to connect each other.

If we want to run more than one node, we can do this by running also the `node_*.sh` scripts that are found on the root of this project and also the `observer_node.sh` that we have to add another node, where we can just run the `observer` for Elixir using `:observer.start()`

#### Stress tests

We have a small utility process, to spawn tasks to just do some random processing and then just make these process to die and terminate eventually. This is done by the `RelaxedProcessesSpawner` process, that we can call using `perform/2`. This function will spawn `n` processes with `m` ttl. The startegy that these spawned processes are distributed, is mainly based on the HordeSupervisor strategy.

an example that will spawn 20 `SleepProcess` with 20 seconds of ttl is with the following command on an iex in the cluster.

```elixir
n = 20
RelaxedProcessesSpawner.start_link_create(n, 20) #will create 20 Relaxed Process and then just make them wait 20 secs to generate a random number
RelaxedProcessesSpawner.start_link_stress_them(n)

## Run this to terminate them
RelaxedProcessesSpawner.start_link_stop(20)
```

### What's Horde?

Horde is a distributed supervisor and a distributed registry. Horde was inspired very heavily by Swarm and built to address some perceived shortcomings of Swarm’s design.

You should use Horde when you want a global supervisor (or global registry, or some combination of the two) that supports automatic fail-over, dynamic cluster membership, and graceful node shutdown.

### Features and differences between Horde and Swarm

Horde mirrors the API of Elixir’s Supervisor and Registry as much as possible, and in fact it runs its own Supervisor per node, distributing processes among the cluster’s nodes using a simple hash function (ala Swarm).

Aside from some additional code to glue together supervisors into a distributed supervisor, Horde should be a drop-in replacement for Elixir’s Supervisor or Registry.

While Swarm’s global process registry blurs the line between a registry and a supervisor (for example, using `register_name/5`, Swarm will start and restart a process for you, but not otherwise supervise your process), Horde maintains a strict separation of supervisor from registry.

This is the biggest difference between Swarm and Horde and resolves some problems stemming from Swarm’s blurring of these concepts.

Thus, Horde provides both Horde.Supervisor and Horde.Registry

### How to send message to the supervised processes by horde??

At some point you’re going to start multiple processes under a distributed supervisor, and you’ll want to communicate with them. The question is: how? 

With a normal application, you would name your processes (which is called “registering” them), and then refer to them by that name.

For the example we have on this minimal example it'd be something like:

```elixir
GenServer.call(PongWorker, :ping)
```

But this mechanism is scoped to a single node. If you know where a process is running, then you can just pass the node where this process is currently in an extra argument:

```elixir
GenServer.call({PongWorker, node}, :ping)
```

But the main issue lies on that we need to know where Horde is going to spawn our `PongWorker` process, also, Horde starts the new process on a random node, o how can you know which node your process is running on to address it with `{name, node}`? The answer is: we need to use `Horde.Registry`.

`Horde.Registry` is a distributed process registry. That means that you can register a process with it, and then access that process from any location in your cluster.

There are a couple of ways you can do this. 

For example, you can call `Horde.Registry.register(registry, :foo)` from within a process (eg, the init/1 callback of a GenServer) to register it. The pid of this process can then be found by calling 

```elixir
Horde.Registry.lookup(registry, :foo)
```

from any node in the cluster. This will work, but there is a nicer approach. We just can use the `via_tuple` in order to get a tuple that will be used to know exactly the process is found and then just call it, once we have its id, it's going to be as calling a process on the cluster. 

```elixir
tuple = IascHordeExample.PongWorker.Starter.via_tuple(PongWorker)
# {:via, Horde.Registry, {HordeRegistry, Elixir.PongWorker}}
# {:via, Horde.Registry, {IascHordeExample.HordeRegistry, Elixir.PongWorker}}
pid = GenServer.whereis(tuple)
GenServer.call(pid, :ping)
```

#### OTP and Horde

One of the best things about Horde is that its Supervisor and Registry both function as OTP building blocks in a way you’re familiar with. This means that common OTP patterns can be utilized with Horde to build distributed supervision trees of arbitrary complexity combined with distributed registries. I’ve included a supervision tree diagram here for illustration.

![](/img/diagram.jpg)

Horde.Supervisor and Horde.Registry are just two new tools in your OTP toolbox.

### what's behind the scenes?

Horde is built on delta-CRDTs. CRDTs (conflict-free replicated data types) are guaranteed to converge (eventually, but Horde communicates aggressively to keep divergences to a minimum)
