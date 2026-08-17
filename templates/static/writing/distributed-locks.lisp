(in-package :templates)
(load "templates/utils.lisp")

(defmacro head ()
  `(with-html
     (page-math-styles)
     (page-code-styles)
     (:meta :name "robots" :content "noindex")))

(defmacro body ()
  `(content
     (header
       "Formally verified distributed locks for sandboxes"
       (page-small :class "mt-5" "Aug 17 2026")
       (blog-intro
         '((page-text
             "I’m wrapping up my internship at Modal, where I worked on our new, massively scalable "
             (page-url-text
               "sandbox architecture"
               "https://modal.com/blog/scaling-to-1-million-concurrent-sandboxes-in-seconds")
             ". The better part of it was spent building "
             (page-italic "names")
             ", a distributed locking primitive for sandboxes. Acquiring a name is the same as acquiring a lock, except sandboxes keep their name until they terminate.")
           (page-text
             "It turns out that distributed systems are hard to get right. Depending on assumptions, some results might even be provably impossible. I had to re-design names more than once: I’d overlook a race, requirements would change, or a decision would cause surprising interactions downstream. Being fed up, I learned "
             (page-url-text "TLA+" "https://lamport.azurewebsites.net/tla/tla.html")
             ", a modelling language built on top of temporal logic, to formally verify the system’s properties.")
           (page-text
             "This post goes into the design and process behind sandbox names. It’s also my first blog post! My hope is that this will be an informative and fun read - if not, I take that personally, so please give me feedback."))
         '(("What is a sandbox?" "what-is-a-sandbox")
           ("Mutual exclusion" "mutual-exclusion")
           ("Is distributed locking hard?" "is-distributed-locking-hard")
           ("Formal properties" "formal-properties")
           ("Scaling up" "scaling-up")
           ("Preemptible locks" "preemptible-locks")
           ("Conclusion" "conclusion"))))

     (section
       (page-subtitle :id "what-is-a-sandbox" "What is a sandbox?")
       (page-text
         "Although I’ve been thinking about sandboxes for a while, you deserve some context. Let’s take a step back: what is a sandbox?")
       (page-text
         "In short, it’s a secure environment where you can run untrusted programs. Sandboxes are abundant today for running agent-generated code to protect your machine from malicious behaviour (à la "
         (page-code "rm -rf /")
         ") - such as for RL rollouts. A single training run might spin up 100s of thousands of sandboxes in parallel, so we need to handle a lot of load.")
       (page-text
         "Now, there’s no free lunch in distributed systems. To architect for reliability and scale, Modal trades consistency for availability. We’re able to continue scheduling new sandboxes even in the face of data store failures, at the cost of accepting eventual consistency. For those familiar, this implies that Modal sandboxes occupy the AP corner of CAP (actually, we’re "
         (page-url-text "PA/EL" "https://en.wikipedia.org/wiki/PACELC_design_principle")
         "; eventual consistency also keeps scheduling latencies low, though this is better explained in the blog post from earlier).")
       (page-text
         "AP works great for most use cases, but users may want stronger guarantees. When mutual exclusion is involved, for example, eventual consistency just doesn’t cut it."))

     (section
       (page-subtitle :id "mutual-exclusion" "Mutual exclusion")
       (page-text
         "Sometimes a sandbox needs exclusive access to a resource. An agent might book flights on your behalf, or an RL episode might interact with a stateful game server. Multiple sandboxes making non-idempotent requests would interfere with each other.")
       (page-text
         "This is better explained with an example. Suppose I have a long-running coding agent working inside a sandbox. I need it to access stateful resources (like a database or repository). If multiple instances of this sandbox spun up, they could end up overwriting each other.")
       (page-text
         "The simple answer here is to just create one sandbox for the agent. However, if the sandbox ever abruptly terminates, I expect it to be re-created - the agent shouldn’t halt. This is more common than it sounds. A process could crash, the network could partition, or the AWS instance could be preempted. Naively recreating the sandbox whenever we hit an error could easily lead to double-creates.")
       (page-text "Well, sounds like this agent needs a mutex."))

     (section
       (page-subtitle :id "is-distributed-locking-hard" "Is distributed locking hard?")
       (page-text
         "Sandbox names act as a mutex, though sandboxes can only hold one name, and hold it until they terminate. Mutexes are also simple: atomic acquires, atomic releases. Any transactional database supports that. Why is this blog post so long?")
       (page-text
         "Consider the situation where a sandbox acquires the mutex, then promptly crashes without releasing the lock.")
       (page-image
         "/public/writing/sandboxes-and-distributed-locks/deadlock.png"
         :caption "Figure 1: A deadlock blocks all future acquires")
       (page-text
         "This is a deadlock! Usually the kernel steps in, detects the process crash, and preempts the lock. But sandboxes are distributed actors, forced to communicate over unreliable networks. How do you tell whether the sandbox crashed or if there’s just a packet delay? You can’t, which makes resolving this deadlock hard.")
       (page-text
         "That being said, distributed locks are more or less a solved problem. There’s a classic "
         (page-url-text
           "blog post"
           "https://martin.kleppmann.com/2016/02/08/how-to-do-distributed-locking.html")
         " by Martin Kleppmann that goes over the standard solution. Let’s work up to this solution, investigate its properties, then break the rules in the name of performance. More on that later.")

       (page-heading "Distributed leasing")
       (page-text
         "How we resolve deadlocks is by implementing a "
         (page-italic "distributed lease")
         ". After initially acquiring the lock, sandboxes must continually refresh it, or else it expires. We call this intermittent ping sent by the sandbox a heartbeat.")
       (page-image
         "/public/writing/sandboxes-and-distributed-locks/lease.png"
         :caption "Figure 2: The lease expires after Sandbox 1 fails to refresh")
       (page-text
         "But networks are still unreliable. What if a sandbox continually fails to heartbeat? The lease might expire, allowing another sandbox to acquire it. To prevent a mutual exclusion (mutex) violation, the sandbox should self-terminate after failing to heartbeat for some time, before the lock is due to expire.")
       (page-image
         "/public/writing/sandboxes-and-distributed-locks/self-terminate.png"
         :caption "Figure 3: Sandbox 1 self-terminates before the lease expires")
       (page-text
         "Is this enough? In his blog, Kleppmann argues no. We can’t rely on time-based methods (like self-termination) because of unreliable clocks and process pauses. It’s true that clock issues can be minimized, but unlucky garbage collection or scheduling starvation might cause a process to pause for an unbounded amount of time. In that case, we could see a mutex violation.")
       (page-image
         "/public/writing/sandboxes-and-distributed-locks/mutex-violation.png"
         :caption "Figure 4: Mutex violations can still occur due to unlucky timing")
       (page-text
         "Thus the final part of a distributed lease is a "
         (page-italic "fencing token")
         ". The lock maintains a monotonic counter that increments after each acquire. When a sandbox acquires the lock, it receives the counter’s value and passes it to the resource as a token. The resource should check to make sure the token is greater or equal to the last seen value, otherwise it rejects the write.")
       (page-image
         "/public/writing/sandboxes-and-distributed-locks/fencing-token.png"
         :caption "Figure 5: The resource rejects token 1 because it has already seen token 2")

       (page-heading "Problems with fencing")
       (page-text
         "Fencing tokens enforce a total order on the writes to a resource and are required for true correctness. But fencing is not always practical: we often don’t have control over the resources used by sandboxes, and Modal doesn’t have a "
         (page-code "Resource")
         " primitive. This is interesting future work, but for now, are fencing tokens even necessary?")
       (page-text
         "We saw earlier that time-based approaches don’t work because they can’t guarantee safety. For our system, let’s use a time-based approach!")
       (page-text
         "I promise this isn’t as silly as it sounds. Recall the original assumptions: clocks cannot be trusted, processes can pause indefinitely. Can we relax these? A monotonic clock won’t jump back, and is unlikely to skew that much. Additionally, our supervisor process (which heartbeats on behalf of sandboxes) definitely does not have a GC. Give it high scheduling priority and CPU pin other processes to shield it, and it’s unlikely to pause for that long.")
       (page-text
         "Network partitions can always happen, but we use our earlier strategy for dealing with them: if heartbeats keep failing, the supervisor initiates a kill-switch that terminates the sandbox before the lock expires.")
       (page-image
         "/public/writing/sandboxes-and-distributed-locks/kill-switch.png"
         :caption "Figure 6: The supervisor heartbeats on behalf of sandboxes, initiating the kill-switch if refreshes fail")
       (page-text
         "Given these relaxed assumptions, the lock should work. But the actual system is a bit more complex than the above diagram. What if there’s a race we’re not thinking of?"))

     (section
       (page-subtitle :id "formal-properties" "Formal properties")
       (page-text
         "Designing correct concurrent systems is hard; the number of behaviours typically grows super-exponentially with size. For sandbox names, there were times where I "
         (page-italic "finally")
         " finished the design only to catch a race in it afterwards. This is especially true for the preemptible lock I discuss later, though even the simple lease has complications. We’ll see why once we try formalizing it.")
       (page-text
         "TLA+ is a logic-based specification language. It was created by Lamport (perhaps better known for Paxos) in the 90s, but emerges from an older research effort to develop practical frameworks for program verification. TLA is based on modal logic (unrelated to Modal), an extension of first-order logic that introduces two new operators: "
         (page-math "\\Box")
         " and "
         (page-math "\\Diamond")
         ". Different modal logics have differing semantics for these; in TLA, they mean "
         (page-italic "always")
         " and "
         (page-italic "eventually")
         ", respectively. With the two, we can express both safety properties (the system is always safe) and liveness properties (the system eventually makes progress).")
       (page-text
         "Using TLA+ involves writing a spec that defines three things: state, properties, and behaviour. I wrote parts of my spec with PlusCal, a language that compiles down to TLA+ but resembles regular code, to make things easier. You’ll see both in the snippets below. Once the spec is written, a model checker like TLC can be ran to automatically verify whether the properties hold.")
       (page-text
         "Note that many details are omitted to get at the bigger picture. If this confuses you, ask Claude to fill in the blanks (or view it on my "
         (page-url-text "Github" "https://github.com/scott-22/tla-specs/blob/main/Lease.tla")
         ").")

       (page-heading "State")
       (page-text
         "The state of our distributed lease can be defined using PlusCal variables. For example, we need to know the lock’s owner ("
         (page-code "Lock")
         "), whether the lease has been refreshed before the expiry TTL ("
         (page-code "Refreshed")
         "), each sandbox’s state ("
         (page-code "Proc")
         "), whether each sandbox is in its critical section ("
         (page-code "Critical")
         "), and whether a heartbeat hit a network partition ("
         (page-code "HeartbeatNetworkFailure")
         ").")
       (page-code-block :tla #{
variables
    Lock = "NONE",
    Refreshed = FALSE,
    Proc = [s \in Sandboxes |-> "INIT"],
    Critical = [s \in Sandboxes |-> FALSE],
    HeartbeatNetworkFailure = [s \in Sandboxes |-> FALSE],
    ...
}#)
       (page-text
         "It is also useful to parameterize our assumptions. Is communication reliable? Can clocks be trusted? Running the model checker reveals which properties hold under which assumptions.")
       (page-code-block :tla #{
CONSTANT UnreliableTiming, UnreliableNetworks
}#)

       (page-heading "Properties")
       (page-text
         "The defining safety property of a lock is mutual exclusion. If a sandbox is in its critical section, then it holds the lock. Or, expressed in TLA:")
       (page-code-block :tla #{
MutualExclusion ==
    \A s \in Sandboxes: Critical[s] => Lock = s
}#)
       (page-text
         "Are we missing something? You might notice that this should "
         (page-italic "always")
         " hold. That is, we really should have:"
         (page-math-block "\\forall s\\in S:\\Box(\\text{Critical}(s)\\to \\text{Lock}=s)")
         "Instead, what we’re doing here is an optimization: tell the model checker that "
         (page-code "MutualExclusion")
         " is an invariant, and it will be checked more efficiently than generic temporal formulas.")
       (page-text
         "The defining liveness property of a lock is deadlock-freedom. One formulation could be that all sandboxes eventually acquire the lock. However, this assumes all sandboxes eventually terminate (they can’t stay critical forever). While technically true, a sandbox’s lifetime can be long enough that our model should treat it as unbounded. So, here’s an alternative statement:")
       (page-code-block :tla #{
Liveness ==
    \A s \in Sandboxes: (~Critical[s] /\ Lock = s) ~> Critical[s] \/ Lock # s
}#)
       (page-text
         "Whenever a sandbox incorrectly holds the lock (is not in its critical section), it will eventually enter the critical section or release the lock. You might notice a lot of funky syntax above: "
         (page-code "~")
         " is negation, "
         (page-code "/\\")
         " is logical conjunction, "
         (page-code "#")
         " is “does not equal”, and "
         (page-code "~>")
         " is "
         (page-italic "leads to")
         ", syntactic sugar for “always if A then eventually B”. Altogether, we have:"
         (page-math-block "\\forall s\\in S: \\Box\\big[(\\lnot\\text{Critical}(s)\\land \\text{Lock}=s)\\to\\Diamond (\\text{Lock}\\ne s)\\big]"))
       (page-text
         "Last, recall that our approach is time-based. If we have "
         (page-code "UnreliableTiming")
         ", then we can’t guarantee mutual exclusion! In this case, we want the system to recover in a bounded amount of time. We can formalize this property as:")
       (page-code-block :tla #{
EventualMutualExclusion ==
    \A s \in Sandboxes: (Critical[s] /\ Lock # s) ~> [](~Critical[s])
}#)
       (page-text
         "Whenever there’s a mutex violation, the offending sandbox eventually self-terminates (leaves the critical section permanently). Removing sugar, the statement becomes:"
         (page-math-block "\\forall s\\in S:\\Box\\big[(\\text{Critical}(s)\\land\\text{Lock}\\ne s)\\to\\Diamond\\Box(\\lnot\\text{Critical}(s))\\big]"))
       (page-text
         "Remember how above I didn’t want to assume that all sandboxes terminate? If so, we’d get "
         (page-code "EventualMutualExclusion")
         " for free without any recovery mechanism. When modelling systems, one generally aims to make the least amount of assumptions possible.")

       (page-heading "Behaviour")
       (page-text
         "The final and most complex piece of the spec is its behaviour. PlusCal represents behaviour via "
         (page-italic "processes")
         " that modify state: each process contains "
         (page-italic "labels")
         " defining which actions happen atomically, and in what order. In other words, a label corresponds to an atomic step taken by the model, and labels across processes can be interleaved in any order.")
       (page-text
         "What processes go into our lease? Top of mind is the sandbox itself, but there’s actually 2 parts to this: the creation flow (when a sandbox is first scheduled and acquires the lock) and the running sandbox process. We’ll model this as 2 separate processes.")
       (page-text
         "Another thing is the worker heartbeat. We saw previously there’s a supervisor process that heartbeats on behalf of sandboxes. In Modal parlance, this per-machine supervisor is the "
         (page-italic "worker")
         " process (the underlying machine is the worker). The heartbeat itself is conceptually 2 different things too: a lease refresh and a timeout-driven kill-switch, which we’ll also represent as 2 processes.")
       (page-text
         "To close out, we have the lock expiry itself, which we also model as a process. That brings us to 5 processes:")
       (page-code-block :tla #{
fair process (sandboxcreation \in SandboxProcess("SandboxCreation")) {
    Create:
        either {
            (* Schedule a named sandbox atomically *)
        } or {
            (* Set name on an existing unnamed sandbox *)
        };
}

process (sandbox \in SandboxProcess("SandboxRunning")) {
    CriticalSection:
        (* The `await` keyword means this label is blocked from running
           until the condition evaluates to true *)
        await Critical[SandboxId(self)];
    Release:
        (* Become non-critical and release lock atomically *)
    Terminate:
        (* Set state to terminated *)
}

fair process (workerheartbeat \in SandboxProcess("WorkerHeartbeat")) {
    Heartbeat:
        while (TRUE) {
            await Critical[SandboxId(self)];
            (* Attempt to refresh lease *)
        }
}

fair process (workersweep = Process("WorkerSweep")) {
    Sweep:
        while (TRUE) {
            (* Kill sandboxes that fail to refresh lease *)
        }
}

fair process (lockproc = Process("LockExpiry")) {
    Expire:
        while (TRUE) {
            (* Expire the lease if not refreshed *)
        }
}
}#)
       (page-text
         "You might notice that all processes are labeled as "
         (page-code "fair")
         " except the "
         (page-code "SandboxRunning")
         " process. In PlusCal, this is called weak fairness: a weakly fair process must eventually get the chance to run, provided it isn’t deadlocked. In my spec, anything that happens in a bounded time interval must be weakly fair. Since sandbox termination isn’t guaranteed, the "
         (page-code "SandboxRunning")
         " process is not fair.")

       (page-heading "Time dependencies")
       (page-text
         "Running the model checker, we see that "
         (page-code "MutualExclusion")
         " is easily violated. We haven’t modelled any temporal dependencies yet! Heartbeats should occur before the kill-switch timeout, and the kill-switch should occur before lock expiry.")
       (page-text
         "A common way of simulating time is to have a counter that represents discrete timesteps. That can get complex, so I instead modelled only the dependencies themselves: if event A happens before event B, we "
         (page-code "await")
         " on the occurrence of A in B. This looks like storing whether an event has occurred:")
       (page-code-block :tla #{
variables
    ...
    LastHeartbeat = [s \in Sandboxes |-> FALSE],
    LastSweep = [s \in Sandboxes |-> FALSE];
}#)
       (page-text "Then defining a temporal dependency:")
       (page-code-block :tla #{
(* The \/ represents logical disjunction *)
HeartbeatBeforeSweep ==
    \/ \A s \in Sandboxes: Critical[s] => LastHeartbeat[s]
    \/ UnreliableTiming
}#)
       (page-text
         "By taking the disjunction with "
         (page-code "UnreliableTiming")
         ", we can parameterize whether these timing relations actually hold.")
       (page-text
         "One timing relation in particular is worth noting. In the creation flow, we acquire the name before scheduling the sandbox. Hence the lock TTL should be greater than the max scheduling time, or it could expire under our feet. That can actually bite us! The scheduler, being eventually consistent, may schedule onto full workers; in that case it retries with exponential backoff under a rather long deadline. TLA helps ensure we explicitly model this relation:")
       (page-code-block :tla #{
AcquiringCompleteBeforeLockExpiry ==
    \/ \A s \in Sandboxes: ~Acquiring[s]
    \/ UnreliableTiming
}#)

       (page-heading "Unreliable networks")
       (page-text
         "Recall we also have "
         (page-code "UnreliableNetworks")
         " as a parameter. If this knob is true, network calls should be allowed to fail, such as when heartbeating:")
       (page-code-block :tla #{
fair process (workerheartbeat \in SandboxProcess("WorkerHeartbeat")) {
    Heartbeat:
        ...
        LastHeartbeat[SandboxId(self)] := TRUE;
        either {
            HeartbeatNetworkFailure[SandboxId(self)] := FALSE;
            (* Attempt to refresh lease *)
        } or {
            await UnreliableNetworks;
            HeartbeatNetworkFailure[SandboxId(self)] := TRUE;
            (* Don't do anything *)
        };
        ...
}
}#)

       (page-heading "Mutex violations")
       (page-text
         "If we have "
         (page-code "UnreliableTiming")
         ", then we can no longer guarantee "
         (page-code "MutualExclusion")
         ". We need some sort of recovery mechanism such that we still ensure "
         (page-code "EventualMutualExclusion")
         ".")
       (page-text
         "To achieve this, a sandbox terminates if it realizes the lease is owned by another sandbox. This can happen every heartbeat:")
       (page-code-block :tla #{
fair process (workerheartbeat \in SandboxProcess("WorkerHeartbeat")) {
    Heartbeat:
        ...
        if (Lock = SandboxId(self)) {
            Refreshed := TRUE;
        } else {
            Critical[SandboxId(self)] := FALSE;
            Proc[SandboxId(self)] := "TERMINATED";
        }
        ...
}
}#)
       (page-text
         "Now running the model checker with "
         (page-code "UnreliableTiming")
         " shows "
         (page-code "MutualExclusion")
         " to be violated, but "
         (page-code "EventualMutualExclusion")
         " to hold."))

     (section
       (page-subtitle :id "scaling-up" "Scaling up")
       (page-text
         "Great - we have a lease that is verifiably correct, given some assumptions. Although the design is simple, verifying still helped us discover that we need a mutex violation recovery mechanism, and that the lock timeout should exceed scheduling latency.")
       (page-text
         "However, consider what happens as we scale the number of named sandboxes. Every sandbox makes a transactional write when refreshing, causing high steady-state load that could exceed what a single database node can handle. Typically, we’d shard the lock table and key by name. But that could be more cost than we actually need!")
       (page-text
         "Let’s do a thought experiment: rather than expiring the lock, what if we made the lock preemptible if the owner has terminated? Then we might do away with heartbeats. In distributed systems, this is called a "
         (page-url-text "failure detector" "https://en.wikipedia.org/wiki/Failure_detector")
         ". Unfortunately for us, perfect ones don’t exist. Failure detectors must choose between completeness (all sandbox failures are reported) or accuracy (we never report false failure). For us, deadlocks are never acceptable, so any failure detector must be complete at the risk of inaccuracy - same as our lease.")
       (page-text
         "Not all hope is lost: there’s one trick we can use by adopting a failure detector model. Instead of "
         (page-math "O(\\text{sandboxes})")
         " liveness updates, we can scale down to "
         (page-math "O(\\text{workers})")
         " liveness updates. If a worker is alive, we can simply ask it if the sandbox is running. Thus detecting sandbox failure reduces down to detecting worker failure!")
       (page-image
         "/public/writing/sandboxes-and-distributed-locks/failure-detector.png"
         :caption "Figure 7: We only need one liveness update per worker rather than per sandbox")
       (page-text
         "At this point, your race-condition alarms should be going off. What if the lock is preempted before we finished scheduling? What if we schedule onto a worker right before liveness expires? What if…?"))

     (section
       (page-subtitle :id "preemptible-locks" "Preemptible locks")
       (page-text
         "When first designing sandbox names, we actually started with the preemptible lock. This proved to be challenging: I kept running into races I hadn’t thought of, so it was hard to be convinced that it worked. TLA was meant to address this - which it did! The race addressed by the third pattern below, for example, was caught by our model checker.")
       (page-text
         "But the process of formalizing the design was difficult and slow. And, certain design patterns - required for correctness - were controversial. For an initial implementation, this wasn’t worth it. A standard lease would suffice.")
       (page-text
         "Still, I wanted the preemptible design to be an option should we ever need to scale. In this section, I cover three patterns for building out a functional preemptible lock. The TLA formalization is complex enough to no longer be informative, so I’ll omit it as an exercise for the reader (or again view it on my "
         (page-url-text "Github" "https://github.com/scott-22/tla-specs/blob/main/Preemptable.tla")
         ").")

       (page-heading "2-Phase Commit")
       (page-text
         "In our creation flow, we want lock acquisition and sandbox creation to behave atomically. Otherwise, we could acquire the lock, preempt it before scheduling the sandbox, then immediately cause a mutex violation.")
       (page-text
         "The standard way to do this is "
         (page-url-text "2-Phase Commit" "https://en.wikipedia.org/wiki/Two-phase_commit_protocol")
         ". The lock has two “taken” states: an intermediate "
         (page-italic "acquiring")
         " state, and a committed "
         (page-italic "acquired")
         " state. In the acquiring state, the lock cannot be preempted. To prevent deadlocks (e.g, if a partition occurs right after acquisition and we fail to schedule the sandbox), an uncommitted lock will expire after some TTL.")
       (page-image
         "/public/writing/sandboxes-and-distributed-locks/two-phase-commit.png"
         :size :large
         :caption "Figure 8: The lock represented as a state machine")
       (page-text
         "A natural question to ask is what if the commit fails? To really make this work, the commit needs to happen via heartbeat. Once confirmed, the sandbox can stop heartbeating. Finally, if commits keep failing, then a kill-switch should activate before lock expiry.")

       (page-heading "Storing worker information")
       (page-text
         "Recall the preemption flow: if the failure detector reports that the worker is unresponsive, then the lock is preemptible. Otherwise, the worker is live and I ask it directly whether the lock owner is still running.")
       (page-text
         "This requires knowing which worker a sandbox lives on, and storing that information in our lock table. We don’t know this information upfront - the control plane acquires the lock before scheduling the sandbox. Thus, worker information should be sent through the commit.")

       (page-heading "Kill-switch synchronization")
       (page-text
         "The kill-switch prevents mutex violations by terminating all sandboxes on a worker whose liveness is about to expire. What if we schedule a sandbox onto it right after?")
       (page-text
         "To prevent yet another mutex violation, we should never create named sandboxes on a worker after its kill-switch initiates until it sends a successful heartbeat and refreshes its liveness.")
       (page-image
         "/public/writing/sandboxes-and-distributed-locks/kill-switch-sync.png"
         :caption "Figure 9: Block named sandboxes after the kill-switch, until liveness is restored")
       (page-text
         "This could be done in two ways: either the scheduler keeps track of this, or the worker does. It’s safer for the worker to do it - one can imagine a packet delay that holds a scheduling request just until the kill-switch triggers, for example.")
       (page-text
         "However, there’s a worker analogue for the exact same situation! That is, the worker receives a request to create a new named sandbox, but the thread is preempted and resumes only after the kill-switch has already triggered. It follows that named sandbox creation and the kill-switch should be synchronized - have I mentioned this blog post is about locks?"))

     (section
       (page-subtitle :id "conclusion" "Conclusion")
       (page-text
         "Distributed systems are about trade-offs. We choose between CP and AP, between liveness and safety, and between durability and latency.")
       (page-text
         "Sometimes it’s ok to break rules if it makes the most sense for the system. However, sometimes we should just do the simplest thing. While the preemptible lock was a fun thought experiment, the added complexity may not be worth it. Today, sandbox names are built on a plain old lease.")
       (page-text
         "Regardless of the choices we make, what we never want is unintended consequences. Assumptions and interactions should be explicit, and the best way to formalize that is mathematically.")
       (page-text
         "Coming into this internship, I knew next to nothing about distributed systems. I’ve grown immensely over the past 4 months, and through trial by fire, had the chance to own systems end-to-end and bring them to life. Thanks for reading, and I hope you learned something!")
       (page-text "Scott :)"))))

(defun writing_distributed-locks ()
  (layout
    :title "Formally verified distributed locks for sandboxes - Scott Hao"
    :description ""
    :head (head)
    :body (body)))
