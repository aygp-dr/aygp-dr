---------------------------- MODULE TopicsDisplay ----------------------------
(* Formal specification for topics display format contract *)

EXTENDS Integers, Sequences, TLC

CONSTANTS 
    Topics,          \* Set of topic names
    MaxTopics,       \* Maximum number of topics to display
    MinCount,        \* Minimum repository count
    MaxCount         \* Maximum repository count

VARIABLES
    topicCounts,     \* Function mapping topics to their counts
    displayOrder,    \* Sequence of topics in display order
    orgFormat,       \* Org-mode formatted output
    htmlFormat       \* HTML formatted output

Init == 
    /\ topicCounts \in [Topics -> MinCount..MaxCount]
    /\ displayOrder = <<>>
    /\ orgFormat = ""
    /\ htmlFormat = ""

TypeInvariant ==
    /\ topicCounts \in [Topics -> MinCount..MaxCount]
    /\ displayOrder \in Seq(Topics)
    /\ orgFormat \in STRING
    /\ htmlFormat \in STRING

(* Topics must be ordered by count (descending) *)
OrderedByCount ==
    \A i, j \in 1..Len(displayOrder):
        i < j => topicCounts[displayOrder[i]] >= topicCounts[displayOrder[j]]

(* Display order contains at most MaxTopics *)
LimitedDisplay ==
    Len(displayOrder) <= MaxTopics

(* No duplicate topics in display *)
UniqueTopics ==
    \A i, j \in 1..Len(displayOrder):
        i # j => displayOrder[i] # displayOrder[j]

(* Format specifications *)
ValidOrgFormat ==
    \* Org format: topic^{count}
    \A t \in Topics:
        t \in Range(displayOrder) => 
            (t \o "^{" \o ToString(topicCounts[t]) \o "}") \in orgFormat

ValidHtmlFormat ==
    \* HTML format: topic<sup>count</sup>
    \A t \in Topics:
        t \in Range(displayOrder) =>
            (t \o "<sup>" \o ToString(topicCounts[t]) \o "</sup>") \in htmlFormat

(* Consistency between formats *)
FormatConsistency ==
    \* Both formats must contain the same topics with same counts
    \A t \in Range(displayOrder):
        /\ (t \o "^{" \o ToString(topicCounts[t]) \o "}") \in orgFormat
        /\ (t \o "<sup>" \o ToString(topicCounts[t]) \o "</sup>") \in htmlFormat

(* Safety property: Display contract *)
DisplayContract ==
    /\ TypeInvariant
    /\ OrderedByCount
    /\ LimitedDisplay
    /\ UniqueTopics
    /\ ValidOrgFormat
    /\ ValidHtmlFormat
    /\ FormatConsistency

=============================================================================