diff --git a/Cargo.lock b/Cargo.lock
index f77c2d8349..73ba2bdca0 100644
--- a/Cargo.lock
+++ b/Cargo.lock
@@ -12986,23 +12986,25 @@ dependencies = [
 [[package]]
 name = "solana-vote-interface"
 version = "3.0.0"
-source = "registry+https://github.com/rust-lang/crates.io-index"
-checksum = "66631ddbe889dab5ec663294648cd1df395ec9df7a4476e7b3e095604cfdb539"
 dependencies = [
  "arbitrary",
  "bincode",
  "cfg_eval",
+ "itertools 0.12.1",
  "num-derive",
  "num-traits",
+ "rand 0.8.5",
  "serde",
  "serde_derive",
  "serde_with",
  "solana-clock 3.0.0",
+ "solana-epoch-schedule 3.0.0",
  "solana-frozen-abi",
  "solana-frozen-abi-macro",
  "solana-hash 3.0.0",
  "solana-instruction 3.0.0",
  "solana-instruction-error",
+ "solana-logger",
  "solana-pubkey 3.0.0",
  "solana-rent 3.0.0",
  "solana-sdk-ids 3.0.0",
diff --git a/Cargo.toml b/Cargo.toml
index f80a55cede..2be43027bb 100644
--- a/Cargo.toml
+++ b/Cargo.toml
@@ -81,6 +81,7 @@ members = [
     "programs/stake-tests",
     "programs/system",
     "programs/vote",
+    "vote-interface",
     "programs/zk-elgamal-proof",
     "programs/zk-elgamal-proof-tests",
     "programs/zk-token-proof",
@@ -569,7 +570,7 @@ solana-unified-scheduler-pool = { path = "unified-scheduler-pool", version = "=3
 solana-validator-exit = "3.0.0"
 solana-version = { path = "version", version = "=3.0.6" }
 solana-vote = { path = "vote", version = "=3.0.6" }
-solana-vote-interface = "3.0.0"
+solana-vote-interface = { path = "vote-interface", version = "=3.0.0" }
 solana-vote-program = { path = "programs/vote", version = "=3.0.6", default-features = false }
 solana-wen-restart = { path = "wen-restart", version = "=3.0.6" }
 solana-zk-elgamal-proof-program = { path = "programs/zk-elgamal-proof", version = "=3.0.6" }
diff --git a/core/src/commitment_service.rs b/core/src/commitment_service.rs
index c6f59efa61..cf782413ec 100644
--- a/core/src/commitment_service.rs
+++ b/core/src/commitment_service.rs
@@ -345,7 +345,7 @@ mod tests {
 
         let root = ancestors[2];
         vote_state.root_slot = Some(root);
-        vote_state.process_next_vote_slot(*ancestors.last().unwrap());
+        vote_state.process_next_vote_slot(*ancestors.last().unwrap(), true);
         AggregateCommitmentService::aggregate_commitment_for_vote_account(
             &mut commitment,
             &mut rooted_stake,
@@ -377,8 +377,8 @@ mod tests {
         let root = ancestors[2];
         vote_state.root_slot = Some(root);
         assert!(ancestors[4] + 2 >= ancestors[6]);
-        vote_state.process_next_vote_slot(ancestors[4]);
-        vote_state.process_next_vote_slot(ancestors[6]);
+        vote_state.process_next_vote_slot(ancestors[4], true);
+        vote_state.process_next_vote_slot(ancestors[6], true);
         AggregateCommitmentService::aggregate_commitment_for_vote_account(
             &mut commitment,
             &mut rooted_stake,
diff --git a/core/src/consensus.rs b/core/src/consensus.rs
index 1bf1b964a7..ca3ff48572 100644
--- a/core/src/consensus.rs
+++ b/core/src/consensus.rs
@@ -44,12 +44,16 @@ use {
     std::{
         cmp::Ordering,
         collections::{HashMap, HashSet},
+        fs::read_to_string,
         ops::{
             Bound::{Included, Unbounded},
             Deref,
         },
+        path::Path,
+        time::SystemTime,
     },
     thiserror::Error,
+    serde::{Deserialize, Serialize},
 };
 
 #[derive(PartialEq, Eq, Clone, Copy, Debug, Default)]
@@ -66,7 +70,7 @@ impl ThresholdDecision {
 }
 
 #[cfg_attr(feature = "frozen-abi", derive(AbiExample))]
-#[derive(PartialEq, Eq, Clone, Debug)]
+#[derive(PartialEq, Eq, Clone, Debug, Serialize, Deserialize)]
 pub enum SwitchForkDecision {
     SwitchProof(Hash),
     SameFork,
@@ -200,7 +204,7 @@ impl TowerVersions {
 }
 
 #[cfg_attr(feature = "frozen-abi", derive(AbiExample))]
-#[derive(PartialEq, Eq, Debug, Default, Clone, Copy)]
+#[derive(PartialEq, Eq, Debug, Default, Clone, Copy, Serialize, Deserialize)]
 pub(crate) enum BlockhashStatus {
     /// No vote since restart
     #[default]
@@ -213,7 +217,7 @@ pub(crate) enum BlockhashStatus {
     Blockhash(Hash),
 }
 
-#[derive(Clone, Debug, PartialEq)]
+#[derive(Clone, Debug, PartialEq, Serialize, Deserialize)]
 pub struct Tower {
     pub node_pubkey: Pubkey,
     pub(crate) threshold_depth: usize,
@@ -235,6 +239,16 @@ pub struct Tower {
     // bank_forks (=~ ledger) lacks the slot or not.
     stray_restored_slot: Option<Slot>,
     pub last_switch_threshold_check: Option<(Slot, SwitchForkDecision)>,
+    #[serde(skip)]
+    pub mostly_confirmed_threshold: Option<f64>,
+    #[serde(skip)]
+    pub threshold_ahead_count: Option<u8>,
+    #[serde(skip)]
+    pub after_skip_threshold: Option<u8>,
+    #[serde(skip)]
+    pub threshold_escape_count: Option<u8>,
+    #[serde(skip)]
+    pub last_config_check_seconds: u64,
 }
 
 impl Default for Tower {
@@ -249,6 +263,11 @@ impl Default for Tower {
             last_vote_tx_blockhash: BlockhashStatus::default(),
             stray_restored_slot: Option::default(),
             last_switch_threshold_check: Option::default(),
+            mostly_confirmed_threshold: None,
+            threshold_ahead_count: None,
+            after_skip_threshold: None,
+            threshold_escape_count: None,
+            last_config_check_seconds: 0,
         };
         // VoteState::root_slot is ensured to be Some in Tower
         tower.vote_state.root_slot = Some(Slot::default());
@@ -288,6 +307,11 @@ impl From<Tower1_14_11> for Tower {
             last_timestamp: tower.last_timestamp,
             stray_restored_slot: tower.stray_restored_slot,
             last_switch_threshold_check: tower.last_switch_threshold_check,
+            mostly_confirmed_threshold: None,
+            threshold_ahead_count: None,
+            after_skip_threshold: None,
+            threshold_escape_count: None,
+            last_config_check_seconds: 0,
         }
     }
 }
@@ -306,6 +330,11 @@ impl From<Tower1_7_14> for Tower {
             last_timestamp: tower.last_timestamp,
             stray_restored_slot: tower.stray_restored_slot,
             last_switch_threshold_check: tower.last_switch_threshold_check,
+            mostly_confirmed_threshold: None,
+            threshold_ahead_count: None,
+            after_skip_threshold: None,
+            threshold_escape_count: None,
+            last_config_check_seconds: 0,
         }
     }
 }
@@ -452,7 +481,7 @@ impl Tower {
                 );
             }
 
-            vote_state.process_next_vote_slot(bank_slot);
+            vote_state.process_next_vote_slot(bank_slot, true);
 
             for vote in &vote_state.votes {
                 vote_slots.insert(vote.slot());
@@ -524,6 +553,26 @@ impl Tower {
         }
     }
 
+    pub fn is_mostly_confirmed_threshold_enabled(&self) -> bool {
+        self.mostly_confirmed_threshold.is_some()
+    }
+
+    pub fn is_slot_mostly_confirmed(
+        &self,
+        slot: Slot,
+        voted_stakes: &VotedStakes,
+        total_stake: Stake,
+    ) -> bool {
+        let mostly_confirmed_threshold =
+            self.mostly_confirmed_threshold
+                .unwrap_or(SWITCH_FORK_THRESHOLD);
+
+        voted_stakes
+            .get(&slot)
+            .map(|stake| (*stake as f64 / total_stake as f64) > mostly_confirmed_threshold)
+            .unwrap_or(false)
+    }
+
     #[cfg(test)]
     fn is_slot_confirmed(
         &self,
@@ -613,7 +662,7 @@ impl Tower {
         vote_account.vote_state_view().last_voted_slot()
     }
 
-    pub fn record_bank_vote(&mut self, bank: &Bank) -> Option<Slot> {
+    pub fn record_bank_vote(&mut self, bank: &Bank, pop_expired: bool) -> Option<Slot> {
         // Returns the new root if one is made after applying a vote for the given bank to
         // `self.vote_state`
         let block_id = bank.block_id().unwrap_or_else(|| {
@@ -629,9 +678,135 @@ impl Tower {
             bank.feature_set
                 .is_active(&agave_feature_set::enable_tower_sync_ix::id()),
             block_id,
+            pop_expired,
         )
     }
 
+    pub fn update_config(&mut self) {
+        // Use this opportunity to possibly load new value for mostly_confirmed_threshold
+        let config_check_seconds = SystemTime::now()
+            .duration_since(SystemTime::UNIX_EPOCH)
+            .ok()
+            .map_or(0, |x| x.as_secs());
+        if config_check_seconds >= (self.last_config_check_seconds + 60) {
+            // Format of mostly_confirmed_threshold:
+            // a.float b.int c.int d.int
+            // a is threshold - no slot that hasn't already achieved this vote weight will be voted on, except for
+            //   slots in the "vote ahead of threshold" region, unless the escape hatch distance has been reached
+            // b is "vote ahead of threshold" - how many slots ahead of the threshold slot to vote, regardless of
+            //   vote weight.  Reduces vote latency.
+            // c controls what stake weighted vote percentage is required on a slot after there have been skips.  It
+            //   must be one of these values:
+            //   0 -- no restriction
+            //   1 -- a slot after a skip has to have mostly_confirmed_threshold before it will be voted on
+            //   2 -- a slot after a skip has to be confirmed already before it will be voted on
+            // d is "escape hatch distance".  This is the number of slots of non-voting while waiting for threshold
+            //   to just vote anyway.  This is an escape hatch to allow network progress even if threshold is not
+            //   being achieved.  Without this, there could be deadlock if all validators ran this voting strategy
+            //   beacuse if multiple forks happen at once, it's possible for all forks to end up with less than
+            //   the threshold vote and no validator would ever switch forks.
+            warn!("Checking for change to mostly_confirmed_threshold");
+            self.last_config_check_seconds = config_check_seconds;
+            match read_to_string(Path::new("./mostly_confirmed_threshold")) {
+                Ok(s) => {
+                    let split = s
+                        .strip_suffix("\n")
+                        .unwrap_or("")
+                        .split_whitespace()
+                        .collect::<Vec<&str>>();
+                    match split.first().copied().unwrap_or("").parse::<f64>() {
+                        Ok(threshold) => {
+                            if let Some(mostly_confirmed_threshold) =
+                                self.mostly_confirmed_threshold
+                            {
+                                if mostly_confirmed_threshold != threshold {
+                                    self.mostly_confirmed_threshold = Some(threshold);
+                                    warn!("Using new mostly_confirmed_threshold: {}", threshold);
+                                }
+                            } else {
+                                self.mostly_confirmed_threshold = Some(threshold);
+                                warn!("Using new mostly_confirmed_threshold: {}", threshold);
+                            }
+                        }
+                        _ => {
+                            warn!("Using NO mostly_confirmed_threshold");
+                            self.mostly_confirmed_threshold = None;
+                        }
+                    }
+                    match split.get(1).unwrap_or(&"").parse::<u8>() {
+                        Ok(count) => {
+                            if let Some(already_count) = self.threshold_ahead_count {
+                                if already_count != count {
+                                    self.threshold_ahead_count = Some(count);
+                                    warn!("Using new threshold_ahead_count: {}", count);
+                                }
+                            } else {
+                                self.threshold_ahead_count = Some(count);
+                                warn!("Using new threshold_ahead_count: {}", count);
+                            }
+                        }
+                        _ => {
+                            warn!("Using NO threshold_ahead_count");
+                            self.threshold_ahead_count = None;
+                        }
+                    }
+                    match split.get(2).unwrap_or(&"").parse::<u8>() {
+                        Ok(threshold) => {
+                            if let Some(already_after_skip_threshold) = self.after_skip_threshold {
+                                if already_after_skip_threshold != threshold {
+                                    self.after_skip_threshold = Some(threshold);
+                                    warn!("Using new after_skip_threshold: {}", threshold);
+                                }
+                            } else {
+                                self.after_skip_threshold = Some(threshold);
+                                warn!("Using new after_skip_threshold: {}", threshold);
+                            }
+                        }
+                        _ => {
+                            warn!("Using NO after_skip_threshold");
+                            self.after_skip_threshold = None;
+                        }
+                    }
+                    match split.get(3).unwrap_or(&"").parse::<u8>() {
+                        Ok(escape) => {
+                            if let Some(already_escape) = self.threshold_escape_count {
+                                if already_escape != escape {
+                                    self.threshold_escape_count = Some(escape);
+                                    warn!("Using new threshold_escape_count: {}", escape);
+                                }
+                            } else {
+                                self.threshold_escape_count = Some(escape);
+                                warn!("Using new threshold_escape_count: {}", escape);
+                            }
+                        }
+                        _ => {
+                            warn!("Using NO threshold_escape_count");
+                            self.threshold_escape_count = None;
+                        }
+                    }
+                }
+                _ => {
+                    warn!("Using NO mostly_confirmed_threshold, threshold_ahead_count, after_skip_threshold, or threshold_escape_count");
+                    self.mostly_confirmed_threshold = None;
+                    self.threshold_ahead_count = None;
+                    self.after_skip_threshold = None;
+                    self.threshold_escape_count = None;
+                }
+            }
+        }
+    }
+    pub fn get_threshold_ahead_count(&self) -> Option<u8> {
+        self.threshold_ahead_count
+    }
+
+    pub fn get_after_skip_threshold(&self) -> Option<u8> {
+        self.after_skip_threshold
+    }
+
+    pub fn get_threshold_escape_count(&self) -> Option<u8> {
+        self.threshold_escape_count
+    }
+
     /// If we've recently updated the vote state by applying a new vote
     /// or syncing from a bank, generate the proper last_vote.
     pub(crate) fn update_last_vote_from_vote_state(
@@ -665,6 +840,7 @@ impl Tower {
         vote_hash: Hash,
         enable_tower_sync_ix: bool,
         block_id: Hash,
+        pop_expired: bool,
     ) -> Option<Slot> {
         if let Some(last_voted_slot) = self.vote_state.last_voted_slot() {
             if vote_slot <= last_voted_slot {
@@ -680,7 +856,7 @@ impl Tower {
         trace!("{} record_vote for {}", self.node_pubkey, vote_slot);
         let old_root = self.root();
 
-        self.vote_state.process_next_vote_slot(vote_slot);
+        self.vote_state.process_next_vote_slot(vote_slot, pop_expired);
         self.update_last_vote_from_vote_state(vote_hash, enable_tower_sync_ix, block_id);
 
         let new_root = self.root();
@@ -699,7 +875,7 @@ impl Tower {
 
     #[cfg(feature = "dev-context-only-utils")]
     pub fn record_vote(&mut self, slot: Slot, hash: Hash) -> Option<Slot> {
-        self.record_bank_vote_and_update_lockouts(slot, hash, true, Hash::default())
+        self.record_bank_vote_and_update_lockouts(slot, hash, true, Hash::default(), true)
     }
 
     #[cfg(feature = "dev-context-only-utils")]
@@ -797,7 +973,49 @@ impl Tower {
         // remaining voted slots are on a different fork from the checked slot,
         // it's still locked out.
         let mut vote_state = self.vote_state.clone();
-        vote_state.process_next_vote_slot(slot);
+        vote_state.process_next_vote_slot(slot, true);
+        for vote in &vote_state.votes {
+            if slot != vote.slot() && !ancestors.contains(&vote.slot()) {
+                return true;
+            }
+        }
+
+        if let Some(root_slot) = vote_state.root_slot {
+            if slot != root_slot {
+                // This case should never happen because bank forks purges all
+                // non-descendants of the root every time root is set
+                assert!(
+                    ancestors.contains(&root_slot),
+                    "ancestors: {ancestors:?}, slot: {slot} root: {root_slot}"
+                );
+            }
+        }
+
+        false
+    }
+
+    // This version first pushes all of the 'including' slots onto the bank before evaluating 'slot'
+    pub fn is_locked_out_including(
+        &self,
+        slot: Slot,
+        ancestors: &HashSet<Slot>,
+        including: &[Slot],
+    ) -> bool {
+        if !self.is_recent(slot) {
+            return true;
+        }
+
+        // Check if a slot is locked out by simulating adding a vote for that
+        // slot to the current lockouts to pop any expired votes. If any of the
+        // remaining voted slots are on a different fork from the checked slot,
+        // it's still locked out.
+        let mut vote_state = self.vote_state.clone();
+
+        for included in including {
+            vote_state.process_next_vote_slot(*included, true);
+        }
+
+        vote_state.process_next_vote_slot(slot, true);
         for vote in &vote_state.votes {
             if slot != vote.slot() && !ancestors.contains(&vote.slot()) {
                 return true;
@@ -818,6 +1036,24 @@ impl Tower {
         false
     }
 
+    pub fn pop_votes_locked_out_at(&self, new_votes: &mut Vec<Slot>, slot: Slot) {
+        let mut vote_state = self.vote_state.clone();
+
+        for i in 0..new_votes.len() {
+            vote_state.process_next_vote_slot(new_votes[i], true);
+            if let Some(last_lockout) = vote_state.last_lockout() {
+                if last_lockout.is_locked_out_at_slot(slot) {
+                    // New votes cannot include this or any subsequent slots
+                    new_votes.truncate(i);
+                    return;
+                }
+            }
+        }
+    }
+
+
+    
+
     /// Checks if a vote for `candidate_slot` is usable in a switching proof
     /// from `last_voted_slot` to `switch_slot`.
     /// We assume `candidate_slot` is not an ancestor of `last_voted_slot`.
@@ -1335,7 +1571,7 @@ impl Tower {
         let mut threshold_decisions = vec![];
         // Generate the vote state assuming this vote is included.
         let mut vote_state = self.vote_state.clone();
-        vote_state.process_next_vote_slot(slot);
+        vote_state.process_next_vote_slot(slot, true);
 
         // Assemble all the vote thresholds and depths to check.
         let vote_thresholds_and_depths = vec![
diff --git a/core/src/consensus/fork_choice.rs b/core/src/consensus/fork_choice.rs
index 5cbf88caa7..591411db55 100644
--- a/core/src/consensus/fork_choice.rs
+++ b/core/src/consensus/fork_choice.rs
@@ -316,6 +316,7 @@ fn can_vote_on_candidate_bank(
     tower: &Tower,
     failure_reasons: &mut Vec<HeaviestForkFailures>,
     switch_fork_decision: &SwitchForkDecision,
+    last_logged_vote_slot: &mut Slot,
 ) -> bool {
     let (
         is_locked_out,
@@ -384,11 +385,14 @@ fn can_vote_on_candidate_bank(
         && propagation_confirmed
         && switch_fork_decision.can_vote()
     {
-        info!(
-            "voting: {} {:.1}%",
-            candidate_vote_bank_slot,
-            100.0 * fork_weight
-        );
+        if candidate_vote_bank_slot != *last_logged_vote_slot {
+            info!(
+                "voting: {} {:.1}%",
+                candidate_vote_bank_slot,
+                100.0 * fork_weight
+            );
+            *last_logged_vote_slot = candidate_vote_bank_slot;
+        }
         true
     } else {
         false
@@ -417,6 +421,7 @@ pub fn select_vote_and_reset_forks(
     tower: &mut Tower,
     latest_validator_votes_for_frozen_banks: &LatestValidatorVotesForFrozenBanks,
     fork_choice: &HeaviestSubtreeForkChoice,
+    last_logged_vote_slot: &mut Slot,
 ) -> SelectVoteAndResetForkResult {
     // Try to vote on the actual heaviest fork. If the heaviest bank is
     // locked out or fails the threshold check, the validator will:
@@ -473,6 +478,7 @@ pub fn select_vote_and_reset_forks(
         tower,
         &mut failure_reasons,
         &switch_fork_decision,
+        last_logged_vote_slot,
     ) {
         // We can vote!
         SelectVoteAndResetForkResult {
diff --git a/core/src/consensus/progress_map.rs b/core/src/consensus/progress_map.rs
index 6d12552124..56fb872612 100644
--- a/core/src/consensus/progress_map.rs
+++ b/core/src/consensus/progress_map.rs
@@ -189,6 +189,7 @@ pub struct ForkStats {
     pub is_locked_out: bool,
     pub voted_stakes: VotedStakes,
     pub duplicate_confirmed_hash: Option<Hash>,
+    pub is_mostly_confirmed: bool,
     pub computed: bool,
     pub lockout_intervals: LockoutIntervals,
     pub bank_hash: Option<Hash>,
@@ -375,6 +376,11 @@ impl ProgressMap {
         slot_progress.fork_stats.duplicate_confirmed_hash = Some(hash);
     }
 
+    pub fn set_mostly_confirmed_slot(&mut self, slot: Slot) {
+        let slot_progress = self.get_mut(&slot).unwrap();
+        slot_progress.fork_stats.is_mostly_confirmed = true;
+    }
+
     pub fn is_duplicate_confirmed(&self, slot: Slot) -> Option<bool> {
         self.progress_map
             .get(&slot)
diff --git a/core/src/consensus/tower_vote_state.rs b/core/src/consensus/tower_vote_state.rs
index a5f69e3568..294bc556aa 100644
--- a/core/src/consensus/tower_vote_state.rs
+++ b/core/src/consensus/tower_vote_state.rs
@@ -1,4 +1,5 @@
 use {
+    serde::{Deserialize, Serialize},
     solana_clock::Slot,
     solana_vote::vote_state_view::VoteStateView,
     solana_vote_program::vote_state::{
@@ -7,7 +8,7 @@ use {
     std::collections::VecDeque,
 };
 
-#[derive(Clone, Debug, PartialEq, Default)]
+#[derive(Clone, Debug, PartialEq, Default, Serialize, Deserialize)]
 pub struct TowerVoteState {
     pub votes: VecDeque<Lockout>,
     pub root_slot: Option<Slot>,
@@ -33,7 +34,7 @@ impl TowerVoteState {
             .and_then(|pos| self.votes.get(pos))
     }
 
-    pub fn process_next_vote_slot(&mut self, next_vote_slot: Slot) {
+    pub fn process_next_vote_slot(&mut self, next_vote_slot: Slot, pop_expired: bool) {
         // Ignore votes for slots earlier than we already have votes for
         if self
             .last_voted_slot()
@@ -42,7 +43,9 @@ impl TowerVoteState {
             return;
         }
 
-        self.pop_expired_votes(next_vote_slot);
+        if pop_expired {
+            self.pop_expired_votes(next_vote_slot);
+        }
 
         // Once the stack is full, pop the oldest lockout and distribute rewards
         if self.votes.len() == MAX_LOCKOUT_HISTORY {
@@ -151,14 +154,14 @@ mod tests {
         let mut vote_state = TowerVoteState::default();
 
         // Process initial vote
-        vote_state.process_next_vote_slot(1);
+        vote_state.process_next_vote_slot(1, true);
         assert_eq!(vote_state.votes.len(), 1);
         assert_eq!(vote_state.votes[0].slot(), 1);
         assert_eq!(vote_state.votes[0].confirmation_count(), 1);
         assert_eq!(vote_state.root_slot, None);
 
         // Process second vote
-        vote_state.process_next_vote_slot(2);
+        vote_state.process_next_vote_slot(2, true);
         assert_eq!(vote_state.votes.len(), 2);
         assert_eq!(vote_state.votes[0].slot(), 1);
         assert_eq!(vote_state.votes[0].confirmation_count(), 2);
@@ -172,7 +175,7 @@ mod tests {
 
         // Fill up the vote history
         for i in 0..(MAX_LOCKOUT_HISTORY + 1) {
-            vote_state.process_next_vote_slot(i as u64);
+            vote_state.process_next_vote_slot(i as u64, true);
         }
 
         // Verify the earliest vote was popped and became the root
@@ -191,12 +194,12 @@ mod tests {
         // second vote
         let top_vote = vote_state.votes.front().unwrap().slot();
         let slot = vote_state.last_lockout().unwrap().last_locked_out_slot();
-        vote_state.process_next_vote_slot(slot);
+        vote_state.process_next_vote_slot(slot, true);
         assert_eq!(Some(top_vote), vote_state.root_slot);
 
         // Expire everything except the first vote
         let slot = vote_state.votes.front().unwrap().last_locked_out_slot();
-        vote_state.process_next_vote_slot(slot);
+        vote_state.process_next_vote_slot(slot, true);
         // First vote and new vote are both stored for a total of 2 votes
         assert_eq!(vote_state.votes.len(), 2);
     }
@@ -206,7 +209,7 @@ mod tests {
         let mut vote_state = TowerVoteState::default();
 
         for i in 0..3 {
-            vote_state.process_next_vote_slot(i as u64);
+            vote_state.process_next_vote_slot(i as u64, true);
         }
 
         check_lockouts(&vote_state);
@@ -214,17 +217,17 @@ mod tests {
         // Expire the third vote (which was a vote for slot 2). The height of the
         // vote stack is unchanged, so none of the previous votes should have
         // doubled in lockout
-        vote_state.process_next_vote_slot((2 + INITIAL_LOCKOUT + 1) as u64);
+        vote_state.process_next_vote_slot((2 + INITIAL_LOCKOUT + 1) as u64, true);
         check_lockouts(&vote_state);
 
         // Vote again, this time the vote stack depth increases, so the votes should
         // double for everybody
-        vote_state.process_next_vote_slot((2 + INITIAL_LOCKOUT + 2) as u64);
+        vote_state.process_next_vote_slot((2 + INITIAL_LOCKOUT + 2) as u64, true);
         check_lockouts(&vote_state);
 
         // Vote again, this time the vote stack depth increases, so the votes should
         // double for everybody
-        vote_state.process_next_vote_slot((2 + INITIAL_LOCKOUT + 3) as u64);
+        vote_state.process_next_vote_slot((2 + INITIAL_LOCKOUT + 3) as u64, true);
         check_lockouts(&vote_state);
     }
 
@@ -233,14 +236,14 @@ mod tests {
         let mut vote_state = TowerVoteState::default();
 
         for i in 0..3 {
-            vote_state.process_next_vote_slot(i as u64);
+            vote_state.process_next_vote_slot(i as u64, true);
         }
 
         assert_eq!(vote_state.votes[0].confirmation_count(), 3);
 
         // Expire the second and third votes
         let expire_slot = vote_state.votes[1].slot() + vote_state.votes[1].lockout() + 1;
-        vote_state.process_next_vote_slot(expire_slot);
+        vote_state.process_next_vote_slot(expire_slot, true);
         assert_eq!(vote_state.votes.len(), 2);
 
         // Check that the old votes expired
@@ -248,7 +251,7 @@ mod tests {
         assert_eq!(vote_state.votes[1].slot(), expire_slot);
 
         // Process one more vote
-        vote_state.process_next_vote_slot(expire_slot + 1);
+        vote_state.process_next_vote_slot(expire_slot + 1, true);
 
         // Confirmation count for the older first vote should remain unchanged
         assert_eq!(vote_state.votes[0].confirmation_count(), 3);
@@ -264,15 +267,15 @@ mod tests {
 
         // Add enough votes to create first root
         for i in 0..(MAX_LOCKOUT_HISTORY + 1) {
-            vote_state.process_next_vote_slot(i as u64);
+            vote_state.process_next_vote_slot(i as u64, true);
         }
         assert_eq!(vote_state.root_slot, Some(0));
 
         // Add more votes to advance root
-        vote_state.process_next_vote_slot(MAX_LOCKOUT_HISTORY as u64 + 1);
+        vote_state.process_next_vote_slot(MAX_LOCKOUT_HISTORY as u64 + 1, true);
         assert_eq!(vote_state.root_slot, Some(1));
 
-        vote_state.process_next_vote_slot(MAX_LOCKOUT_HISTORY as u64 + 2);
+        vote_state.process_next_vote_slot(MAX_LOCKOUT_HISTORY as u64 + 2, true);
         assert_eq!(vote_state.root_slot, Some(2));
     }
 
@@ -281,11 +284,11 @@ mod tests {
         let mut vote_state = TowerVoteState::default();
 
         // Process initial votes
-        vote_state.process_next_vote_slot(1);
-        vote_state.process_next_vote_slot(2);
+        vote_state.process_next_vote_slot(1, true);
+        vote_state.process_next_vote_slot(2, true);
 
         // Try duplicate vote
-        vote_state.process_next_vote_slot(1);
+        vote_state.process_next_vote_slot(1, true);
 
         // Verify the vote state (duplicate should not affect anything)
         assert_eq!(vote_state.votes.len(), 2);
@@ -293,7 +296,7 @@ mod tests {
         assert_eq!(vote_state.votes[1].slot(), 2);
 
         // Try duplicate vote
-        vote_state.process_next_vote_slot(2);
+        vote_state.process_next_vote_slot(2, true);
 
         // Verify the vote state (duplicate should not affect anything)
         assert_eq!(vote_state.votes.len(), 2);
@@ -309,8 +312,8 @@ mod tests {
         };
 
         // Add votes after root
-        vote_state.process_next_vote_slot(6);
-        vote_state.process_next_vote_slot(7);
+        vote_state.process_next_vote_slot(6, true);
+        vote_state.process_next_vote_slot(7, true);
 
         // Verify votes after root are tracked
         assert_eq!(vote_state.votes.len(), 2);
@@ -320,7 +323,7 @@ mod tests {
 
         // Fill up vote history to advance root
         for i in 8..=(MAX_LOCKOUT_HISTORY as u64 + 8) {
-            vote_state.process_next_vote_slot(i);
+            vote_state.process_next_vote_slot(i, true);
         }
 
         // Verify root has advanced
diff --git a/core/src/replay_stage.rs b/core/src/replay_stage.rs
index 1395ae50de..783571ef29 100644
--- a/core/src/replay_stage.rs
+++ b/core/src/replay_stage.rs
@@ -76,6 +76,7 @@ use {
     solana_time_utils::timestamp,
     solana_transaction::Transaction,
     solana_vote::vote_transaction::VoteTransaction,
+    solana_vote_program::vote_state::MAX_LOCKOUT_HISTORY,
     std::{
         collections::{HashMap, HashSet},
         num::{NonZeroUsize, Saturating},
@@ -716,6 +717,8 @@ impl ReplayStage {
                 &leader_schedule_cache,
             );
 
+            let mut last_logged_vote_slot = 0;
+
             loop {
                 // Stop getting entries if we get exit signal
                 if exit.load(Ordering::Relaxed) {
@@ -894,7 +897,7 @@ impl ReplayStage {
                 let mut compute_slot_stats_time = Measure::start("compute_slot_stats_time");
                 for slot in newly_computed_slot_stats {
                     let fork_stats = progress.get_fork_stats(slot).unwrap();
-                    let duplicate_confirmed_forks = Self::tower_duplicate_confirmed_forks(
+                    let (duplicate_confirmed_forks, mostly_confirmed_slots) = Self::tower_duplicate_confirmed_forks(
                         &tower,
                         &fork_stats.voted_stakes,
                         fork_stats.total_stake,
@@ -904,6 +907,7 @@ impl ReplayStage {
 
                     Self::mark_slots_duplicate_confirmed(
                         &duplicate_confirmed_forks,
+                        &mostly_confirmed_slots,
                         &blockstore,
                         &bank_forks,
                         &mut progress,
@@ -946,6 +950,7 @@ impl ReplayStage {
                     &mut tower,
                     &latest_validator_votes_for_frozen_banks,
                     &tbft_structs.heaviest_subtree_fork_choice,
+                    &mut last_logged_vote_slot,
                 );
                 select_vote_and_reset_forks_time.stop();
 
@@ -979,6 +984,8 @@ impl ReplayStage {
                 }
                 heaviest_fork_failures_time.stop();
 
+                tower.update_config();
+
                 let mut voting_time = Measure::start("voting_time");
                 // Vote on a fork
                 if let Some((ref vote_bank, ref switch_fork_decision)) = vote_bank {
@@ -993,32 +1000,199 @@ impl ReplayStage {
                         );
                     }
 
-                    if let Err(e) = Self::handle_votable_bank(
-                        vote_bank,
-                        switch_fork_decision,
-                        &bank_forks,
-                        &mut tower,
-                        &mut progress,
-                        &vote_account,
-                        &identity_keypair,
-                        &authorized_voter_keypairs.read().unwrap(),
-                        &blockstore,
-                        &leader_schedule_cache,
-                        &lockouts_sender,
-                        snapshot_controller.as_deref(),
-                        rpc_subscriptions.as_deref(),
-                        &block_commitment_cache,
-                        &bank_notification_sender,
-                        &mut tracked_vote_transactions,
-                        &mut has_new_vote_been_rooted,
-                        &mut replay_timing,
-                        &voting_sender,
-                        &drop_bank_sender,
-                        wait_to_vote_slot,
-                        &mut tbft_structs,
-                    ) {
-                        error!("Unable to set root: {e}");
-                        return;
+                    let mut vote_banks: Vec<Arc<Bank>> = Vec::new();
+                    let mut pop_expired = true;
+
+                    if let Some(threshold_ahead_count) = tower.get_threshold_ahead_count() {
+                        let most_recent_voted_slot = tower.tower_slots().last().cloned();
+
+                        if let Some(mostly_confirmed_bank) =
+                            ReplayStage::first_mostly_confirmed_bank(vote_bank.clone(), &progress)
+                        {
+                            if let Some(most_recent_voted_slot) = most_recent_voted_slot {
+                                if let Some(mostly_confirmed_bank_parent) =
+                                    mostly_confirmed_bank.parent()
+                                {
+                                    vote_banks = ReplayStage::banks_between_and_including(
+                                        most_recent_voted_slot + 1,
+                                        mostly_confirmed_bank_parent.clone(),
+                                    );
+                                }
+                            }
+
+                            vote_banks.extend(
+                                ReplayStage::banks_between_and_including(
+                                    mostly_confirmed_bank.slot(),
+                                    vote_bank.clone(),
+                                )
+                                .into_iter()
+                                .take((threshold_ahead_count + 1) as usize),
+                            );
+
+                            let after_skip_threshold = tower.get_after_skip_threshold();
+                            let mut filtered_vote_banks = Vec::new();
+                            let mut filtered_vote_slots = Vec::new();
+
+                            for bank in &vote_banks {
+                                if bank.slot() <= most_recent_voted_slot.unwrap_or(0) {
+                                    continue;
+                                }
+
+                                if tower.is_locked_out_including(
+                                    bank.slot(),
+                                    ancestors.get(&bank.slot()).unwrap(),
+                                    &filtered_vote_slots,
+                                ) {
+                                    info!(
+                                        "vote-optimizer cannot vote on {} because it's locked out",
+                                        bank.slot()
+                                    );
+                                    continue;
+                                }
+
+                                if bank.slot()
+                                    > bank
+                                        .parent()
+                                        .map(|parent| parent.slot())
+                                        .unwrap_or_default()
+                                        + 1
+                                {
+                                    match after_skip_threshold {
+                                        Some(1) => {
+                                            if !progress
+                                                .get_fork_stats(bank.slot())
+                                                .unwrap()
+                                                .is_mostly_confirmed
+                                            {
+                                                info!(
+                                                    "vote-optimizer skipping {} due to threshold",
+                                                    bank.slot()
+                                                );
+                                                continue;
+                                            }
+                                        }
+                                        Some(2) => {
+                                            let confirmed_slot = ReplayStage::last_confirmed_slot(
+                                                bank.parent().unwrap().as_ref(),
+                                                &progress,
+                                            );
+                                            if confirmed_slot != bank.parent().unwrap().slot() {
+                                                info!(
+                                                    "vote-optimizer skipping {} due to confirmation threshold",
+                                                    bank.slot()
+                                                );
+                                                continue;
+                                            }
+                                        }
+                                        _ => {}
+                                    }
+                                }
+
+                                filtered_vote_slots.push(bank.slot());
+                                filtered_vote_banks.push(bank.clone());
+                            }
+
+                            if filtered_vote_banks.len() > MAX_LOCKOUT_HISTORY {
+                                let first_slot_to_not_lock_out =
+                                    filtered_vote_slots[filtered_vote_slots.len()
+                                        - MAX_LOCKOUT_HISTORY];
+                                tower.pop_votes_locked_out_at(
+                                    &mut filtered_vote_slots,
+                                    first_slot_to_not_lock_out - 1,
+                                );
+                                filtered_vote_banks.truncate(filtered_vote_slots.len());
+                            }
+
+                            vote_banks = filtered_vote_banks;
+
+                            if vote_banks.is_empty() {
+                                if let Some(threshold_escape_count) =
+                                    tower.get_threshold_escape_count()
+                                {
+                                    if let Some(most_recent_voted_slot) = most_recent_voted_slot {
+                                        let mut unvoted_banks = Vec::new();
+                                        let mut unvoted_slots = Vec::new();
+
+                                        for bank in ReplayStage::banks_between_and_including(
+                                            most_recent_voted_slot + 1,
+                                            vote_bank.clone(),
+                                        ) {
+                                            if !tower.is_locked_out_including(
+                                                bank.slot(),
+                                                ancestors.get(&bank.slot()).unwrap(),
+                                                &unvoted_slots,
+                                            ) {
+                                                unvoted_slots.push(bank.slot());
+                                                unvoted_banks.push(bank.clone());
+                                            }
+                                        }
+
+                                        if unvoted_banks.len()
+                                            > threshold_escape_count as usize
+                                        {
+                                            info!(
+                                                "vote-optimizer voting on escape slot {}",
+                                                unvoted_banks[0].slot()
+                                            );
+                                            vote_banks.push(unvoted_banks[0].clone());
+                                        }
+                                    } else {
+                                        info!(
+                                            "vote-optimizer never voted, so voting on {}",
+                                            vote_bank.slot()
+                                        );
+                                        vote_banks.push(vote_bank.clone());
+                                    }
+                                }
+                            }
+
+                            if let Some(last_new_vote) = vote_banks.last() {
+                                let ancestors = ancestors.get(&last_new_vote.slot()).unwrap();
+                                while let Some(vote) = tower.vote_state.last_lockout() {
+                                    if !ancestors.contains(&vote.slot()) {
+                                        info!("vote-optimizer purged {}", vote.slot());
+                                        tower.vote_state.votes.pop_back();
+                                    } else {
+                                        break;
+                                    }
+                                }
+                            }
+
+                            pop_expired = false;
+                        }
+                    } else {
+                        vote_banks.push(vote_bank.clone());
+                    }
+
+                    if !vote_banks.is_empty() {
+                        if let Err(e) = Self::handle_votable_banks(
+                            &vote_banks,
+                            switch_fork_decision,
+                            &bank_forks,
+                            &mut tower,
+                            &mut progress,
+                            &vote_account,
+                            &identity_keypair,
+                            &authorized_voter_keypairs.read().unwrap(),
+                            &blockstore,
+                            &leader_schedule_cache,
+                            &lockouts_sender,
+                            snapshot_controller.as_deref(),
+                            rpc_subscriptions.as_deref(),
+                            &block_commitment_cache,
+                            &bank_notification_sender,
+                            &mut tracked_vote_transactions,
+                            &mut has_new_vote_been_rooted,
+                            &mut replay_timing,
+                            &voting_sender,
+                            &drop_bank_sender,
+                            wait_to_vote_slot,
+                            &mut tbft_structs,
+                            pop_expired,
+                        ) {
+                            error!("Unable to set root: {e}");
+                            return;
+                        }
                     }
                 }
                 voting_time.stop();
@@ -1380,6 +1554,57 @@ impl ReplayStage {
         }
     }
 
+    fn first_mostly_confirmed_bank(bank: Arc<Bank>, progress: &ProgressMap) -> Option<Arc<Bank>> {
+        if progress
+            .get_fork_stats(bank.slot())
+            .unwrap()
+            .is_mostly_confirmed
+        {
+            Some(bank.clone())
+        } else if let Some(parent) = bank.parent() {
+            ReplayStage::first_mostly_confirmed_bank(parent.clone(), progress)
+        } else {
+            None
+        }
+    }
+
+    fn last_confirmed_slot(bank: &Bank, progress: &ProgressMap) -> Slot {
+        if progress
+            .get_fork_stats(bank.slot())
+            .unwrap()
+            .duplicate_confirmed_hash.is_some()
+        {
+            bank.slot()
+        } else if let Some(parent) = bank.parent() {
+            ReplayStage::last_confirmed_slot(&parent, progress)
+        } else {
+            0
+        }
+    }
+
+    fn banks_between_and_including(first_slot: u64, last_bank: Arc<Bank>) -> Vec<Arc<Bank>> {
+        let mut banks = vec![];
+
+        let mut bank = last_bank;
+
+        loop {
+            if bank.slot() < first_slot {
+                break;
+            }
+
+            banks.push(bank.clone());
+
+            if let Some(parent) = bank.parent() {
+                bank = parent.clone();
+            } else {
+                break;
+            }
+        }
+
+        banks.into_iter().rev().collect()
+    }
+
+
     fn is_partition_detected(
         ancestors: &HashMap<Slot, HashSet<Slot>>,
         last_voted_slot: Slot,
@@ -2370,8 +2595,8 @@ impl ReplayStage {
     }
 
     #[allow(clippy::too_many_arguments)]
-    fn handle_votable_bank(
-        bank: &Arc<Bank>,
+    fn handle_votable_banks(
+        banks: &[Arc<Bank>],
         switch_fork_decision: &SwitchForkDecision,
         bank_forks: &Arc<RwLock<BankForks>>,
         tower: &mut Tower,
@@ -2393,69 +2618,63 @@ impl ReplayStage {
         drop_bank_sender: &Sender<Vec<BankWithScheduler>>,
         wait_to_vote_slot: Option<Slot>,
         tbft_structs: &mut TowerBFTStructures,
+        pop_expired: bool,
     ) -> Result<(), SetRootError> {
-        if bank.is_empty() {
-            datapoint_info!("replay_stage-voted_empty_bank", ("slot", bank.slot(), i64));
-        }
-        trace!("handle votable bank {}", bank.slot());
-        let new_root = tower.record_bank_vote(bank);
+        assert!(!banks.is_empty());
 
-        if let Some(new_root) = new_root {
-            let highest_super_majority_root = Some(
-                block_commitment_cache
-                    .read()
-                    .unwrap()
-                    .highest_super_majority_root(),
+        let mut new_slots = Vec::with_capacity(banks.len());
+
+        for bank in banks.iter() {
+            if bank.is_empty() {
+                datapoint_info!("replay_stage-voted_empty_bank", ("slot", bank.slot(), i64));
+            }
+            trace!("handle votable bank {}", bank.slot());
+            new_slots.push(bank.slot());
+
+            let new_root = tower.record_bank_vote(bank, pop_expired);
+
+            if let Some(new_root) = new_root {
+                let highest_super_majority_root = Some(
+                    block_commitment_cache
+                        .read()
+                        .unwrap()
+                        .highest_super_majority_root(),
+                );
+                Self::check_and_handle_new_root(
+                    &identity_keypair.pubkey(),
+                    bank.parent_slot(),
+                    new_root,
+                    bank_forks,
+                    progress,
+                    blockstore,
+                    leader_schedule_cache,
+                    snapshot_controller,
+                    rpc_subscriptions,
+                    highest_super_majority_root,
+                    bank_notification_sender,
+                    has_new_vote_been_rooted,
+                    tracked_vote_transactions,
+                    drop_bank_sender,
+                    tbft_structs,
+                )?;
+            }
+
+            let mut update_commitment_cache_time = Measure::start("update_commitment_cache");
+            let node_vote_state = (*vote_account_pubkey, tower.vote_state.clone());
+            Self::update_commitment_cache(
+                bank.clone(),
+                bank_forks.read().unwrap().root(),
+                progress.get_fork_stats(bank.slot()).unwrap().total_stake,
+                node_vote_state,
+                lockouts_sender,
             );
-            Self::check_and_handle_new_root(
-                &identity_keypair.pubkey(),
-                bank.parent_slot(),
-                new_root,
-                bank_forks,
-                progress,
-                blockstore,
-                leader_schedule_cache,
-                snapshot_controller,
-                rpc_subscriptions,
-                highest_super_majority_root,
-                bank_notification_sender,
-                has_new_vote_been_rooted,
-                tracked_vote_transactions,
-                drop_bank_sender,
-                tbft_structs,
-            )?;
+            update_commitment_cache_time.stop();
+            replay_timing.update_commitment_cache_us += update_commitment_cache_time.as_us();
         }
 
-        let mut update_commitment_cache_time = Measure::start("update_commitment_cache");
-        // Send (voted) bank along with the updated vote account state for this node, the vote
-        // state is always newer than the one in the bank by definition, because banks can't
-        // contain vote transactions which are voting on its own slot.
-        //
-        // It should be acceptable to aggressively use the vote for our own _local view_ of
-        // commitment aggregation, although it's not guaranteed that the new vote transaction is
-        // observed by other nodes at this point.
-        //
-        // The justification stems from the assumption of the sensible voting behavior from the
-        // consensus subsystem. That's because it means there would be a slashing possibility
-        // otherwise.
-        //
-        // This behavior isn't significant normally for mainnet-beta, because staked nodes aren't
-        // servicing RPC requests. However, this eliminates artificial 1-slot delay of the
-        // `finalized` confirmation if a node is materially staked and servicing RPC requests at
-        // the same time for development purposes.
-        let node_vote_state = (*vote_account_pubkey, tower.vote_state.clone());
-        Self::update_commitment_cache(
-            bank.clone(),
-            bank_forks.read().unwrap().root(),
-            progress.get_fork_stats(bank.slot()).unwrap().total_stake,
-            node_vote_state,
-            lockouts_sender,
-        );
-        update_commitment_cache_time.stop();
-        replay_timing.update_commitment_cache_us += update_commitment_cache_time.as_us();
-
+        info!("voting for window: {:?}", new_slots);
         Self::push_vote(
-            bank,
+            banks.last().unwrap(),
             vote_account_pubkey,
             identity_keypair,
             authorized_voter_keypairs,
@@ -3875,6 +4094,7 @@ impl ReplayStage {
     #[allow(clippy::too_many_arguments)]
     fn mark_slots_duplicate_confirmed(
         confirmed_slots: &[(Slot, Hash)],
+        mostly_confirmed_slots: &[Slot],
         blockstore: &Blockstore,
         bank_forks: &RwLock<BankForks>,
         progress: &mut ProgressMap,
@@ -3923,17 +4143,24 @@ impl ReplayStage {
                 SlotStateUpdate::DuplicateConfirmed(duplicate_confirmed_state),
             );
         }
+        for slot in mostly_confirmed_slots.iter() {
+            progress.set_mostly_confirmed_slot(*slot);
+        }
     }
 
+    /// Returns tuple of (duplicate_confirmed_forks, mostly_confirmed_slots)
     fn tower_duplicate_confirmed_forks(
         tower: &Tower,
         voted_stakes: &VotedStakes,
         total_stake: Stake,
         progress: &ProgressMap,
         bank_forks: &RwLock<BankForks>,
-    ) -> Vec<(Slot, Hash)> {
+    ) -> (Vec<(Slot, Hash)>, Vec<Slot>) {
         let mut duplicate_confirmed_forks = vec![];
+        let mut mostly_confirmed_forks = vec![];
+
         for (slot, prog) in progress.iter() {
+            // Skip if already marked as duplicate confirmed
             if prog.fork_stats.duplicate_confirmed_hash.is_some() {
                 continue;
             }
@@ -3952,6 +4179,8 @@ impl ReplayStage {
             if !bank.is_frozen() {
                 continue;
             }
+
+            // Check for duplicate confirmation
             if tower.is_slot_duplicate_confirmed(*slot, voted_stakes, total_stake) {
                 info!(
                     "validator fork duplicate confirmed {} {}ms",
@@ -3970,8 +4199,13 @@ impl ReplayStage {
                     voted_stakes.get(slot)
                 );
             }
+
+            // Check for mostly confirmed status
+            if tower.is_slot_mostly_confirmed(*slot, voted_stakes, total_stake) {
+                mostly_confirmed_forks.push(*slot);
+            }
         }
-        duplicate_confirmed_forks
+        (duplicate_confirmed_forks, mostly_confirmed_forks)
     }
 
     #[allow(clippy::too_many_arguments)]
@@ -5385,7 +5619,7 @@ pub(crate) mod tests {
         // bank 1, so no slot should be confirmed.
         {
             let fork_progress = progress.get(&0).unwrap();
-            let confirmed_forks = ReplayStage::tower_duplicate_confirmed_forks(
+            let (confirmed_forks, _) = ReplayStage::tower_duplicate_confirmed_forks(
                 &tower,
                 &fork_progress.fork_stats.voted_stakes,
                 fork_progress.fork_stats.total_stake,
@@ -5434,7 +5668,7 @@ pub(crate) mod tests {
         assert_eq!(newly_computed, vec![1]);
         {
             let fork_progress = progress.get(&1).unwrap();
-            let confirmed_forks = ReplayStage::tower_duplicate_confirmed_forks(
+            let (confirmed_forks, _) = ReplayStage::tower_duplicate_confirmed_forks(
                 &tower,
                 &fork_progress.fork_stats.voted_stakes,
                 fork_progress.fork_stats.total_stake,
@@ -6747,7 +6981,7 @@ pub(crate) mod tests {
         assert_eq!(reset_fork.unwrap(), 4);
 
         // Record the vote for 5 which is not on the heaviest fork.
-        tower.record_bank_vote(&bank_forks.read().unwrap().get(5).unwrap());
+        tower.record_bank_vote(&bank_forks.read().unwrap().get(5).unwrap(), true);
 
         // 4 should be the heaviest slot, but should not be votable
         // because of lockout. 5 is the heaviest slot on the same fork as the last vote.
@@ -6966,7 +7200,7 @@ pub(crate) mod tests {
         assert_eq!(reset_fork.unwrap(), 4);
 
         // Record the vote for 4
-        tower.record_bank_vote(&bank_forks.read().unwrap().get(4).unwrap());
+        tower.record_bank_vote(&bank_forks.read().unwrap().get(4).unwrap(), true);
 
         // Mark 4 as duplicate, 3 should be the heaviest slot, but should not be votable
         // because of lockout
@@ -7200,7 +7434,7 @@ pub(crate) mod tests {
             ..
         } = vote_simulator;
 
-        tower.record_bank_vote(&bank_forks.read().unwrap().get(first_vote).unwrap());
+        tower.record_bank_vote(&bank_forks.read().unwrap().get(first_vote).unwrap(), true);
 
         // Simulate another version of slot 2 was duplicate confirmed
         let our_bank2_hash = bank_forks.read().unwrap().bank_hash(2).unwrap();
@@ -7318,6 +7552,7 @@ pub(crate) mod tests {
             .select_forks(&frozen_banks, &tower, &progress, &ancestors, &bank_forks);
         assert_eq!(heaviest_bank.slot(), 7);
         assert!(heaviest_bank_on_same_fork.is_none());
+        let mut junk = 0;
         select_vote_and_reset_forks(
             &heaviest_bank,
             heaviest_bank_on_same_fork.as_ref(),
@@ -7327,6 +7562,7 @@ pub(crate) mod tests {
             &mut tower,
             &latest_validator_votes_for_frozen_banks,
             &tbft_structs.heaviest_subtree_fork_choice,
+            &mut junk,
         )
     }
 
@@ -7441,6 +7677,7 @@ pub(crate) mod tests {
             .select_forks(&frozen_banks, &tower, &progress, &ancestors, &bank_forks);
         assert_eq!(heaviest_bank.slot(), 5);
         assert!(heaviest_bank_on_same_fork.is_none());
+        let mut junk = 0;
         select_vote_and_reset_forks(
             &heaviest_bank,
             heaviest_bank_on_same_fork.as_ref(),
@@ -7450,6 +7687,7 @@ pub(crate) mod tests {
             &mut tower,
             &latest_validator_votes_for_frozen_banks,
             &tbft_structs.heaviest_subtree_fork_choice,
+            &mut junk,
         )
     }
 
@@ -7634,7 +7872,7 @@ pub(crate) mod tests {
                 0,
             ),
         );
-        tower.record_bank_vote(&bank0);
+        tower.record_bank_vote(&bank0, true);
         ReplayStage::push_vote(
             &bank0,
             &my_vote_pubkey,
@@ -7739,7 +7977,7 @@ pub(crate) mod tests {
 
         // Simulate submitting a new vote for bank 1 to the network, but the vote
         // not landing
-        tower.record_bank_vote(&bank1);
+        tower.record_bank_vote(&bank1, true);
         ReplayStage::push_vote(
             &bank1,
             &my_vote_pubkey,
@@ -8010,7 +8248,7 @@ pub(crate) mod tests {
         progress: &mut ProgressMap,
     ) -> Arc<Bank> {
         let my_vote_pubkey = &my_vote_keypair[0].pubkey();
-        tower.record_bank_vote(&parent_bank);
+        tower.record_bank_vote(&parent_bank, true);
         ReplayStage::push_vote(
             &parent_bank,
             my_vote_pubkey,
@@ -8226,6 +8464,7 @@ pub(crate) mod tests {
         assert_eq!(tower.last_voted_slot(), Some(last_voted_slot));
         assert_eq!(progress.my_latest_landed_vote(tip_of_voted_fork), Some(0));
         let other_fork_bank = &bank_forks.read().unwrap().get(other_fork_slot).unwrap();
+        let mut junk = 0;
         let SelectVoteAndResetForkResult { vote_bank, .. } = select_vote_and_reset_forks(
             other_fork_bank,
             Some(&new_bank),
@@ -8235,6 +8474,7 @@ pub(crate) mod tests {
             &mut tower,
             &latest_validator_votes_for_frozen_banks,
             &tbft_structs.heaviest_subtree_fork_choice,
+            &mut junk,
         );
         assert!(vote_bank.is_some());
         assert_eq!(vote_bank.unwrap().0.slot(), tip_of_voted_fork);
@@ -8242,6 +8482,7 @@ pub(crate) mod tests {
         // If last vote is already equal to heaviest_bank_on_same_voted_fork,
         // we should not vote.
         let last_voted_bank = &bank_forks.read().unwrap().get(last_voted_slot).unwrap();
+        let mut junk = 0;
         let SelectVoteAndResetForkResult { vote_bank, .. } = select_vote_and_reset_forks(
             other_fork_bank,
             Some(last_voted_bank),
@@ -8251,12 +8492,14 @@ pub(crate) mod tests {
             &mut tower,
             &latest_validator_votes_for_frozen_banks,
             &tbft_structs.heaviest_subtree_fork_choice,
+            &mut junk,
         );
         assert!(vote_bank.is_none());
 
         // If last vote is still inside slot hashes history of heaviest_bank_on_same_voted_fork,
         // we should not vote.
         let last_voted_bank_plus_1 = &bank_forks.read().unwrap().get(last_voted_slot + 1).unwrap();
+        let mut junk = 0;
         let SelectVoteAndResetForkResult { vote_bank, .. } = select_vote_and_reset_forks(
             other_fork_bank,
             Some(last_voted_bank_plus_1),
@@ -8266,6 +8509,7 @@ pub(crate) mod tests {
             &mut tower,
             &latest_validator_votes_for_frozen_banks,
             &tbft_structs.heaviest_subtree_fork_choice,
+            &mut junk,
         );
         assert!(vote_bank.is_none());
 
@@ -8274,6 +8518,7 @@ pub(crate) mod tests {
             .entry(new_bank.slot())
             .and_modify(|s| s.fork_stats.my_latest_landed_vote = Some(last_voted_slot));
         assert!(!new_bank.is_in_slot_hashes_history(&last_voted_slot));
+        let mut junk = 0;
         let SelectVoteAndResetForkResult { vote_bank, .. } = select_vote_and_reset_forks(
             other_fork_bank,
             Some(&new_bank),
@@ -8283,6 +8528,7 @@ pub(crate) mod tests {
             &mut tower,
             &latest_validator_votes_for_frozen_banks,
             &tbft_structs.heaviest_subtree_fork_choice,
+            &mut junk,
         );
         assert!(vote_bank.is_none());
     }
@@ -8745,6 +8991,7 @@ pub(crate) mod tests {
         );
         let (heaviest_bank, heaviest_bank_on_same_fork) = heaviest_subtree_fork_choice
             .select_forks(&frozen_banks, tower, progress, ancestors, bank_forks);
+        let mut junk = 0;
         let SelectVoteAndResetForkResult {
             vote_bank,
             reset_bank,
@@ -8758,6 +9005,7 @@ pub(crate) mod tests {
             tower,
             latest_validator_votes_for_frozen_banks,
             heaviest_subtree_fork_choice,
+            &mut junk,
         );
         (
             vote_bank.map(|(b, _)| b.slot()),
@@ -9388,6 +9636,7 @@ pub(crate) mod tests {
         let confirmed_slots = [(0, bank_hash_0)];
         ReplayStage::mark_slots_duplicate_confirmed(
             &confirmed_slots,
+            &[],
             &blockstore,
             &bank_forks,
             &mut progress,
@@ -9408,6 +9657,7 @@ pub(crate) mod tests {
 
         ReplayStage::mark_slots_duplicate_confirmed(
             &confirmed_slots,
+            &[],
             &blockstore,
             &bank_forks,
             &mut progress,
@@ -9432,6 +9682,7 @@ pub(crate) mod tests {
 
         ReplayStage::mark_slots_duplicate_confirmed(
             &confirmed_slots,
+            &[],
             &blockstore,
             &bank_forks,
             &mut progress,
@@ -9459,6 +9710,7 @@ pub(crate) mod tests {
         let confirmed_slots = [(6, Hash::new_unique())];
         ReplayStage::mark_slots_duplicate_confirmed(
             &confirmed_slots,
+            &[],
             &blockstore,
             &bank_forks,
             &mut progress,
diff --git a/core/src/vote_simulator.rs b/core/src/vote_simulator.rs
index 6ab59c5bf4..fa7be311b0 100644
--- a/core/src/vote_simulator.rs
+++ b/core/src/vote_simulator.rs
@@ -112,7 +112,7 @@ impl VoteSimulator {
                         parent_bank.get_vote_account(&keypairs.vote_keypair.pubkey())
                     {
                         let mut vote_state = TowerVoteState::from(vote_account.vote_state_view());
-                        vote_state.process_next_vote_slot(parent);
+                        vote_state.process_next_vote_slot(parent, true);
                         TowerSync::new(
                             vote_state.votes,
                             vote_state.root_slot,
@@ -207,6 +207,7 @@ impl VoteSimulator {
 
         // Try to vote on the given slot
         let descendants = self.bank_forks.read().unwrap().descendants();
+        let mut last_logged_vote_slot = 0;
         let SelectVoteAndResetForkResult {
             heaviest_fork_failures,
             ..
@@ -219,6 +220,7 @@ impl VoteSimulator {
             tower,
             &self.latest_validator_votes_for_frozen_banks,
             &self.tbft_structs.heaviest_subtree_fork_choice,
+            &mut last_logged_vote_slot,
         );
 
         // Make sure this slot isn't locked out or failing threshold
@@ -227,7 +229,7 @@ impl VoteSimulator {
             return heaviest_fork_failures;
         }
 
-        let new_root = tower.record_bank_vote(&vote_bank);
+        let new_root = tower.record_bank_vote(&vote_bank, true);
         if let Some(new_root) = new_root {
             self.set_root(new_root);
         }
diff --git a/programs/sbf/Cargo.lock b/programs/sbf/Cargo.lock
index 4bb8b4bcc1..39ee197cea 100644
--- a/programs/sbf/Cargo.lock
+++ b/programs/sbf/Cargo.lock
@@ -11110,8 +11110,6 @@ dependencies = [
 [[package]]
 name = "solana-vote-interface"
 version = "3.0.0"
-source = "registry+https://github.com/rust-lang/crates.io-index"
-checksum = "66631ddbe889dab5ec663294648cd1df395ec9df7a4476e7b3e095604cfdb539"
 dependencies = [
  "bincode",
  "cfg_eval",
diff --git a/programs/vote/benches/process_vote.rs b/programs/vote/benches/process_vote.rs
index 0ce1ae92ef..af9658cd67 100644
--- a/programs/vote/benches/process_vote.rs
+++ b/programs/vote/benches/process_vote.rs
@@ -50,7 +50,7 @@ fn create_accounts() -> (Slot, SlotHashes, Vec<TransactionAccount>, Vec<AccountM
         );
 
         for next_vote_slot in 0..num_initial_votes {
-            vote_state.process_next_vote_slot(next_vote_slot, 0, 0);
+            vote_state.process_next_vote_slot(next_vote_slot, 0, 0, true);
         }
         let mut vote_account_data: Vec<u8> = vec![0; VoteStateV3::size_of()];
         let versioned = VoteStateVersions::new_v3(vote_state);
diff --git a/programs/vote/benches/vote_instructions.rs b/programs/vote/benches/vote_instructions.rs
index 9836d114ed..fefd170fd1 100644
--- a/programs/vote/benches/vote_instructions.rs
+++ b/programs/vote/benches/vote_instructions.rs
@@ -59,7 +59,7 @@ fn create_accounts() -> (Slot, SlotHashes, Vec<TransactionAccount>, Vec<AccountM
         );
 
         for next_vote_slot in 0..num_initial_votes {
-            vote_state.process_next_vote_slot(next_vote_slot, 0, 0);
+            vote_state.process_next_vote_slot(next_vote_slot, 0, 0, true);
         }
         let mut vote_account_data: Vec<u8> = vec![0; VoteStateV3::size_of()];
         let versioned = VoteStateVersions::new_v3(vote_state);
diff --git a/programs/vote/src/vote_state/mod.rs b/programs/vote/src/vote_state/mod.rs
index 7bd7c26ca5..ab4e80a801 100644
--- a/programs/vote/src/vote_state/mod.rs
+++ b/programs/vote/src/vote_state/mod.rs
@@ -612,11 +612,12 @@ pub fn process_vote_unfiltered(
     slot_hashes: &[SlotHash],
     epoch: Epoch,
     current_slot: Slot,
+    pop_expired: bool,
 ) -> Result<(), VoteError> {
     check_slots_are_valid(vote_state, vote_slots, &vote.hash, slot_hashes)?;
     vote_slots
         .iter()
-        .for_each(|s| vote_state.process_next_vote_slot(*s, epoch, current_slot));
+        .for_each(|s| vote_state.process_next_vote_slot(*s, epoch, current_slot, pop_expired));
     Ok(())
 }
 
@@ -647,11 +648,16 @@ pub fn process_vote(
         slot_hashes,
         epoch,
         current_slot,
+        true,
     )
 }
 
 /// "unchecked" functions used by tests and Tower
-pub fn process_vote_unchecked(vote_state: &mut VoteStateV3, vote: Vote) -> Result<(), VoteError> {
+pub fn process_vote_unchecked(
+    vote_state: &mut VoteStateV3,
+    vote: Vote,
+    pop_expired: bool,
+) -> Result<(), VoteError> {
     if vote.slots.is_empty() {
         return Err(VoteError::EmptySlots);
     }
@@ -663,6 +669,7 @@ pub fn process_vote_unchecked(vote_state: &mut VoteStateV3, vote: Vote) -> Resul
         &slot_hashes,
         vote_state.current_epoch(),
         0,
+        pop_expired,
     )
 }
 
@@ -674,7 +681,7 @@ pub fn process_slot_votes_unchecked(vote_state: &mut VoteStateV3, slots: &[Slot]
 }
 
 pub fn process_slot_vote_unchecked(vote_state: &mut VoteStateV3, slot: Slot) {
-    let _ = process_vote_unchecked(vote_state, Vote::new(vec![slot], Hash::default()));
+    let _ = process_vote_unchecked(vote_state, Vote::new(vec![slot], Hash::default()), true);
 }
 
 /// Authorize the given pubkey to withdraw or sign votes. This may be called multiple times,
@@ -1140,7 +1147,7 @@ mod tests {
             134, 135,
         ]
         .into_iter()
-        .for_each(|v| vote_state.process_next_vote_slot(v, 4, 0));
+        .for_each(|v| vote_state.process_next_vote_slot(v, 4, 0, true));
 
         let version1_14_11_serialized = bincode::serialize(&VoteStateVersions::V1_14_11(Box::new(
             VoteState1_14_11::from(vote_state.clone()),
@@ -1800,6 +1807,7 @@ mod tests {
                     hash: Hash::new_unique(),
                     timestamp: None,
                 },
+                true,
             )
             .unwrap();
 
@@ -2809,7 +2817,7 @@ mod tests {
                 .unwrap()
                 .1;
             let vote = Vote::new(vote_slots, vote_hash);
-            process_vote_unfiltered(&mut vote_state, &vote.slots, &vote, slot_hashes, 0, 0)
+            process_vote_unfiltered(&mut vote_state, &vote.slots, &vote, slot_hashes, 0, 0, true)
                 .unwrap();
         }
 
diff --git a/runtime/src/snapshot_utils/snapshot_storage_rebuilder.rs b/runtime/src/snapshot_utils/snapshot_storage_rebuilder.rs
index 5c84082982..ffd6b70158 100644
--- a/runtime/src/snapshot_utils/snapshot_storage_rebuilder.rs
+++ b/runtime/src/snapshot_utils/snapshot_storage_rebuilder.rs
@@ -172,20 +172,19 @@ impl SnapshotStorageRebuilder {
     ) {
         thread_pool.spawn(move || {
             for path in rebuilder.file_receiver.iter() {
-                match rebuilder.process_append_vec_file(path) {
-                    Ok(_) => {}
-                    Err(err) => {
-                        exit_sender
-                            .send(Err(err))
-                            .expect("sender should be connected");
+            match rebuilder.process_append_vec_file(path) {
+                Ok(_) => {}
+                Err(err) => {
+                        warn!("snapshot storage rebuilder worker encountered error: {err}");
+                        if exit_sender.send(Err(err)).is_err() {
+                            return;
+                        }
                         return;
                     }
                 }
             }
 
-            exit_sender
-                .send(Ok(()))
-                .expect("sender should be connected");
+            let _ = exit_sender.send(Ok(()));
         })
     }
 
diff --git a/vote-interface/.cargo-ok b/vote-interface/.cargo-ok
new file mode 100644
index 0000000000..5f8b795830
--- /dev/null
+++ b/vote-interface/.cargo-ok
@@ -0,0 +1 @@
+{"v":1}
\ No newline at end of file
diff --git a/vote-interface/.cargo_vcs_info.json b/vote-interface/.cargo_vcs_info.json
new file mode 100644
index 0000000000..cf9da44571
--- /dev/null
+++ b/vote-interface/.cargo_vcs_info.json
@@ -0,0 +1,6 @@
+{
+  "git": {
+    "sha1": "85272d5e37a74541365acb426dac661eda3af268"
+  },
+  "path_in_vcs": "vote-interface"
+}
\ No newline at end of file
diff --git a/vote-interface/Cargo.toml b/vote-interface/Cargo.toml
new file mode 100644
index 0000000000..7c66bca8c1
--- /dev/null
+++ b/vote-interface/Cargo.toml
@@ -0,0 +1,184 @@
+# THIS FILE IS AUTOMATICALLY GENERATED BY CARGO
+#
+# When uploading crates to the registry Cargo will automatically
+# "normalize" Cargo.toml files for maximal compatibility
+# with all versions of Cargo and also rewrite `path` dependencies
+# to registry (e.g., crates.io) dependencies.
+#
+# If you are reading this file be aware that the original Cargo.toml
+# will likely look very different (and much more reasonable).
+# See Cargo.toml.orig for the original contents.
+
+[package]
+edition = "2021"
+rust-version = "1.81.0"
+name = "solana-vote-interface"
+version = "3.0.0"
+authors = ["Anza Maintainers <maintainers@anza.xyz>"]
+build = false
+autolib = false
+autobins = false
+autoexamples = false
+autotests = false
+autobenches = false
+description = "Solana vote interface."
+homepage = "https://anza.xyz/"
+documentation = "https://docs.rs/solana-vote-interface"
+readme = false
+license = "Apache-2.0"
+repository = "https://github.com/anza-xyz/solana-sdk"
+
+[package.metadata.docs.rs]
+all-features = true
+rustdoc-args = ["--cfg=docsrs"]
+targets = ["x86_64-unknown-linux-gnu"]
+
+[features]
+bincode = [
+    "dep:bincode",
+    "dep:solana-serialize-utils",
+    "dep:solana-system-interface",
+    "serde",
+]
+dev-context-only-utils = [
+    "bincode",
+    "dep:arbitrary",
+    "solana-pubkey/dev-context-only-utils",
+]
+frozen-abi = [
+    "dep:solana-frozen-abi",
+    "dep:solana-frozen-abi-macro",
+    "serde",
+    "solana-hash/frozen-abi",
+    "solana-pubkey/frozen-abi",
+    "solana-short-vec/frozen-abi",
+]
+serde = [
+    "dep:cfg_eval",
+    "dep:serde",
+    "dep:serde_derive",
+    "dep:serde_with",
+    "dep:solana-serde-varint",
+    "dep:solana-short-vec",
+    "solana-hash/serde",
+    "solana-pubkey/serde",
+]
+
+[lib]
+name = "solana_vote_interface"
+path = "src/lib.rs"
+
+[dependencies.arbitrary]
+version = "1.4.1"
+features = ["derive"]
+optional = true
+
+[dependencies.bincode]
+version = "1.3.3"
+optional = true
+
+[dependencies.cfg_eval]
+version = "0.1.2"
+optional = true
+
+[dependencies.num-derive]
+version = "0.4"
+
+[dependencies.num-traits]
+version = "0.2.18"
+
+[dependencies.serde]
+version = "1.0.217"
+optional = true
+
+[dependencies.serde_derive]
+version = "1.0.217"
+optional = true
+
+[dependencies.serde_with]
+version = "3.12.0"
+features = ["macros"]
+optional = true
+default-features = false
+
+[dependencies.solana-clock]
+version = "3.0.0"
+
+[dependencies.solana-frozen-abi]
+version = "3.0.0"
+features = ["frozen-abi"]
+optional = true
+
+[dependencies.solana-frozen-abi-macro]
+version = "3.0.0"
+features = ["frozen-abi"]
+optional = true
+
+[dependencies.solana-hash]
+version = "3.0.0"
+default-features = false
+
+[dependencies.solana-instruction]
+version = "3.0.0"
+features = ["std"]
+default-features = false
+
+[dependencies.solana-instruction-error]
+version = "2.0.0"
+features = ["num-traits"]
+
+[dependencies.solana-pubkey]
+version = "3.0.0"
+default-features = false
+
+[dependencies.solana-rent]
+version = "3.0.0"
+default-features = false
+
+[dependencies.solana-sdk-ids]
+version = "3.0.0"
+
+[dependencies.solana-serde-varint]
+version = "3.0.0"
+optional = true
+
+[dependencies.solana-serialize-utils]
+version = "3.0.0"
+optional = true
+
+[dependencies.solana-short-vec]
+version = "3.0.0"
+optional = true
+
+[dependencies.solana-system-interface]
+version = "2.0"
+features = ["bincode"]
+optional = true
+
+[dev-dependencies.itertools]
+version = "0.12.1"
+
+[dev-dependencies.rand]
+version = "0.8.5"
+
+[dev-dependencies.solana-epoch-schedule]
+version = "3.0.0"
+
+[dev-dependencies.solana-logger]
+version = "3.0.0"
+
+[dev-dependencies.solana-pubkey]
+version = "3.0.0"
+features = ["dev-context-only-utils"]
+default-features = false
+
+[target.'cfg(target_os = "solana")'.dependencies.solana-serialize-utils]
+version = "3.0.0"
+
+[lints.rust.unexpected_cfgs]
+level = "warn"
+priority = 0
+check-cfg = [
+    'cfg(target_os, values("solana"))',
+    'cfg(feature, values("frozen-abi", "no-entrypoint"))',
+]
diff --git a/vote-interface/Cargo.toml.orig b/vote-interface/Cargo.toml.orig
new file mode 100644
index 0000000000..0cc111580d
--- /dev/null
+++ b/vote-interface/Cargo.toml.orig
@@ -0,0 +1,88 @@
+[package]
+name = "solana-vote-interface"
+description = "Solana vote interface."
+documentation = "https://docs.rs/solana-vote-interface"
+version = "3.0.0"
+rust-version = "1.81.0"
+authors = { workspace = true }
+repository = { workspace = true }
+homepage = { workspace = true }
+license = { workspace = true }
+edition = { workspace = true }
+
+[package.metadata.docs.rs]
+targets = ["x86_64-unknown-linux-gnu"]
+all-features = true
+rustdoc-args = ["--cfg=docsrs"]
+
+[features]
+bincode = [
+    "dep:bincode",
+    "dep:solana-serialize-utils",
+    "dep:solana-system-interface",
+    "serde",
+]
+dev-context-only-utils = [
+    "bincode",
+    "dep:arbitrary",
+    "solana-pubkey/dev-context-only-utils",
+]
+frozen-abi = [
+    "dep:solana-frozen-abi",
+    "dep:solana-frozen-abi-macro",
+    "serde",
+    "solana-hash/frozen-abi",
+    "solana-pubkey/frozen-abi",
+    "solana-short-vec/frozen-abi",
+]
+serde = [
+    "dep:cfg_eval",
+    "dep:serde",
+    "dep:serde_derive",
+    "dep:serde_with",
+    "dep:solana-serde-varint",
+    "dep:solana-short-vec",
+    "solana-hash/serde",
+    "solana-pubkey/serde",
+]
+
+[dependencies]
+arbitrary = { workspace = true, features = ["derive"], optional = true }
+bincode = { workspace = true, optional = true }
+cfg_eval = { workspace = true, optional = true }
+num-derive = { workspace = true }
+num-traits = { workspace = true }
+serde = { workspace = true, optional = true }
+serde_derive = { workspace = true, optional = true }
+serde_with = { workspace = true, features = ["macros"], optional = true }
+solana-clock = { workspace = true }
+solana-frozen-abi = { workspace = true, features = [
+    "frozen-abi",
+], optional = true }
+solana-frozen-abi-macro = { workspace = true, features = [
+    "frozen-abi",
+], optional = true }
+solana-hash = { workspace = true }
+solana-instruction = { workspace = true, features = ["std"] }
+solana-instruction-error = { workspace = true, features = ["num-traits"] }
+solana-pubkey = { workspace = true }
+solana-rent = { workspace = true }
+solana-sdk-ids = { workspace = true }
+solana-serde-varint = { workspace = true, optional = true }
+solana-serialize-utils = { workspace = true, optional = true }
+solana-short-vec = { workspace = true, optional = true }
+solana-system-interface = { workspace = true, features = ["bincode"], optional = true }
+
+[target.'cfg(target_os = "solana")'.dependencies]
+solana-serialize-utils = { workspace = true }
+
+[dev-dependencies]
+itertools = { workspace = true }
+rand = { workspace = true }
+solana-epoch-schedule = { workspace = true }
+solana-logger = { workspace = true }
+solana-pubkey = { workspace = true, features = ["dev-context-only-utils"] }
+solana-vote-interface = { path = ".", features = ["dev-context-only-utils"] }
+
+[lints]
+workspace = true
diff --git a/vote-interface/src/authorized_voters.rs b/vote-interface/src/authorized_voters.rs
new file mode 100644
index 0000000000..cb47e89ff9
--- /dev/null
+++ b/vote-interface/src/authorized_voters.rs
@@ -0,0 +1,112 @@
+#[cfg(feature = "dev-context-only-utils")]
+use arbitrary::Arbitrary;
+#[cfg(feature = "serde")]
+use serde_derive::{Deserialize, Serialize};
+use {solana_clock::Epoch, solana_pubkey::Pubkey, std::collections::BTreeMap};
+
+#[cfg_attr(feature = "frozen-abi", derive(solana_frozen_abi_macro::AbiExample))]
+#[cfg_attr(feature = "serde", derive(Deserialize, Serialize))]
+#[derive(Debug, Default, PartialEq, Eq, Clone)]
+#[cfg_attr(feature = "dev-context-only-utils", derive(Arbitrary))]
+pub struct AuthorizedVoters {
+    authorized_voters: BTreeMap<Epoch, Pubkey>,
+}
+
+impl AuthorizedVoters {
+    pub fn new(epoch: Epoch, pubkey: Pubkey) -> Self {
+        let mut authorized_voters = BTreeMap::new();
+        authorized_voters.insert(epoch, pubkey);
+        Self { authorized_voters }
+    }
+
+    pub fn get_authorized_voter(&self, epoch: Epoch) -> Option<Pubkey> {
+        self.get_or_calculate_authorized_voter_for_epoch(epoch)
+            .map(|(pubkey, _)| pubkey)
+    }
+
+    pub fn get_and_cache_authorized_voter_for_epoch(&mut self, epoch: Epoch) -> Option<Pubkey> {
+        let res = self.get_or_calculate_authorized_voter_for_epoch(epoch);
+
+        res.map(|(pubkey, existed)| {
+            if !existed {
+                self.authorized_voters.insert(epoch, pubkey);
+            }
+            pubkey
+        })
+    }
+
+    pub fn insert(&mut self, epoch: Epoch, authorized_voter: Pubkey) {
+        self.authorized_voters.insert(epoch, authorized_voter);
+    }
+
+    pub fn purge_authorized_voters(&mut self, current_epoch: Epoch) -> bool {
+        // Iterate through the keys in order, filtering out the ones
+        // less than the current epoch
+        let expired_keys: Vec<_> = self
+            .authorized_voters
+            .range(0..current_epoch)
+            .map(|(authorized_epoch, _)| *authorized_epoch)
+            .collect();
+
+        for key in expired_keys {
+            self.authorized_voters.remove(&key);
+        }
+
+        // Have to uphold this invariant b/c this is
+        // 1) The check for whether the vote state is initialized
+        // 2) How future authorized voters for uninitialized epochs are set
+        //    by this function
+        assert!(!self.authorized_voters.is_empty());
+        true
+    }
+
+    pub fn is_empty(&self) -> bool {
+        self.authorized_voters.is_empty()
+    }
+
+    pub fn first(&self) -> Option<(&u64, &Pubkey)> {
+        self.authorized_voters.iter().next()
+    }
+
+    pub fn last(&self) -> Option<(&u64, &Pubkey)> {
+        self.authorized_voters.iter().next_back()
+    }
+
+    pub fn len(&self) -> usize {
+        self.authorized_voters.len()
+    }
+
+    pub fn contains(&self, epoch: Epoch) -> bool {
+        self.authorized_voters.contains_key(&epoch)
+    }
+
+    pub fn iter(&self) -> std::collections::btree_map::Iter<'_, Epoch, Pubkey> {
+        self.authorized_voters.iter()
+    }
+
+    // Returns the authorized voter at the given epoch if the epoch is >= the
+    // current epoch, and a bool indicating whether the entry for this epoch
+    // exists in the self.authorized_voter map
+    fn get_or_calculate_authorized_voter_for_epoch(&self, epoch: Epoch) -> Option<(Pubkey, bool)> {
+        let res = self.authorized_voters.get(&epoch);
+        if res.is_none() {
+            // If no authorized voter has been set yet for this epoch,
+            // this must mean the authorized voter remains unchanged
+            // from the latest epoch before this one
+            let res = self.authorized_voters.range(0..epoch).next_back();
+
+            /*
+            if res.is_none() {
+                warn!(
+                    "Tried to query for the authorized voter of an epoch earlier
+                    than the current epoch. Earlier epochs have been purged"
+                );
+            }
+            */
+
+            res.map(|(_, pubkey)| (*pubkey, false))
+        } else {
+            res.map(|pubkey| (*pubkey, true))
+        }
+    }
+}
diff --git a/vote-interface/src/error.rs b/vote-interface/src/error.rs
new file mode 100644
index 0000000000..573c13cbd0
--- /dev/null
+++ b/vote-interface/src/error.rs
@@ -0,0 +1,73 @@
+//! Vote program errors
+
+use {
+    core::fmt,
+    num_derive::{FromPrimitive, ToPrimitive},
+};
+
+/// Reasons the vote might have had an error
+#[derive(Debug, Clone, PartialEq, Eq, FromPrimitive, ToPrimitive)]
+pub enum VoteError {
+    VoteTooOld,
+    SlotsMismatch,
+    SlotHashMismatch,
+    EmptySlots,
+    TimestampTooOld,
+    TooSoonToReauthorize,
+    // TODO: figure out how to migrate these new errors
+    LockoutConflict,
+    NewVoteStateLockoutMismatch,
+    SlotsNotOrdered,
+    ConfirmationsNotOrdered,
+    ZeroConfirmations,
+    ConfirmationTooLarge,
+    RootRollBack,
+    ConfirmationRollBack,
+    SlotSmallerThanRoot,
+    TooManyVotes,
+    VotesTooOldAllFiltered,
+    RootOnDifferentFork,
+    ActiveVoteAccountClose,
+    CommissionUpdateTooLate,
+    AssertionFailed,
+}
+
+impl core::error::Error for VoteError {}
+
+impl fmt::Display for VoteError {
+    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
+        f.write_str(match self {
+            Self::VoteTooOld => "vote already recorded or not in slot hashes history",
+            Self::SlotsMismatch => "vote slots do not match bank history",
+            Self::SlotHashMismatch => "vote hash does not match bank hash",
+            Self::EmptySlots => "vote has no slots, invalid",
+            Self::TimestampTooOld => "vote timestamp not recent",
+            Self::TooSoonToReauthorize => "authorized voter has already been changed this epoch",
+            Self::LockoutConflict => {
+                "Old state had vote which should not have been popped off by vote in new state"
+            }
+            Self::NewVoteStateLockoutMismatch => {
+                "Proposed state had earlier slot which should have been popped off by later vote"
+            }
+            Self::SlotsNotOrdered => "Vote slots are not ordered",
+            Self::ConfirmationsNotOrdered => "Confirmations are not ordered",
+            Self::ZeroConfirmations => "Zero confirmations",
+            Self::ConfirmationTooLarge => "Confirmation exceeds limit",
+            Self::RootRollBack => "Root rolled back",
+            Self::ConfirmationRollBack => {
+                "Confirmations for same vote were smaller in new proposed state"
+            }
+            Self::SlotSmallerThanRoot => "New state contained a vote slot smaller than the root",
+            Self::TooManyVotes => "New state contained too many votes",
+            Self::VotesTooOldAllFiltered => {
+                "every slot in the vote was older than the SlotHashes history"
+            }
+            Self::RootOnDifferentFork => "Proposed root is not in slot hashes",
+            Self::ActiveVoteAccountClose => {
+                "Cannot close vote account unless it stopped voting at least one full epoch ago"
+            }
+            Self::CommissionUpdateTooLate => "Cannot update commission at this point in the epoch",
+            Self::AssertionFailed => "Assertion failed",
+        })
+    }
+}
diff --git a/vote-interface/src/instruction.rs b/vote-interface/src/instruction.rs
new file mode 100644
index 0000000000..fa65245281
--- /dev/null
+++ b/vote-interface/src/instruction.rs
@@ -0,0 +1,598 @@
+//! Vote program instructions
+
+use {
+    super::state::TowerSync,
+    crate::state::{
+        Vote, VoteAuthorize, VoteAuthorizeCheckedWithSeedArgs, VoteAuthorizeWithSeedArgs, VoteInit,
+        VoteStateUpdate, VoteStateVersions,
+    },
+    solana_clock::{Slot, UnixTimestamp},
+    solana_hash::Hash,
+    solana_pubkey::Pubkey,
+};
+#[cfg(feature = "bincode")]
+use {
+    crate::program::id,
+    solana_instruction::{AccountMeta, Instruction},
+    solana_sdk_ids::sysvar,
+};
+#[cfg(feature = "serde")]
+use {
+    crate::state::{serde_compact_vote_state_update, serde_tower_sync},
+    serde_derive::{Deserialize, Serialize},
+};
+
+#[cfg_attr(feature = "serde", derive(Deserialize, Serialize))]
+#[derive(Debug, PartialEq, Eq, Clone)]
+pub enum VoteInstruction {
+    /// Initialize a vote account
+    ///
+    /// # Account references
+    ///   0. `[WRITE]` Uninitialized vote account
+    ///   1. `[]` Rent sysvar
+    ///   2. `[]` Clock sysvar
+    ///   3. `[SIGNER]` New validator identity (node_pubkey)
+    InitializeAccount(VoteInit),
+
+    /// Authorize a key to send votes or issue a withdrawal
+    ///
+    /// # Account references
+    ///   0. `[WRITE]` Vote account to be updated with the Pubkey for authorization
+    ///   1. `[]` Clock sysvar
+    ///   2. `[SIGNER]` Vote or withdraw authority
+    Authorize(Pubkey, VoteAuthorize),
+
+    /// A Vote instruction with recent votes
+    ///
+    /// # Account references
+    ///   0. `[WRITE]` Vote account to vote with
+    ///   1. `[]` Slot hashes sysvar
+    ///   2. `[]` Clock sysvar
+    ///   3. `[SIGNER]` Vote authority
+    Vote(Vote),
+
+    /// Withdraw some amount of funds
+    ///
+    /// # Account references
+    ///   0. `[WRITE]` Vote account to withdraw from
+    ///   1. `[WRITE]` Recipient account
+    ///   2. `[SIGNER]` Withdraw authority
+    Withdraw(u64),
+
+    /// Update the vote account's validator identity (node_pubkey)
+    ///
+    /// # Account references
+    ///   0. `[WRITE]` Vote account to be updated with the given authority public key
+    ///   1. `[SIGNER]` New validator identity (node_pubkey)
+    ///   2. `[SIGNER]` Withdraw authority
+    UpdateValidatorIdentity,
+
+    /// Update the commission for the vote account
+    ///
+    /// # Account references
+    ///   0. `[WRITE]` Vote account to be updated
+    ///   1. `[SIGNER]` Withdraw authority
+    UpdateCommission(u8),
+
+    /// A Vote instruction with recent votes
+    ///
+    /// # Account references
+    ///   0. `[WRITE]` Vote account to vote with
+    ///   1. `[]` Slot hashes sysvar
+    ///   2. `[]` Clock sysvar
+    ///   3. `[SIGNER]` Vote authority
+    VoteSwitch(Vote, Hash),
+
+    /// Authorize a key to send votes or issue a withdrawal
+    ///
+    /// This instruction behaves like `Authorize` with the additional requirement that the new vote
+    /// or withdraw authority must also be a signer.
+    ///
+    /// # Account references
+    ///   0. `[WRITE]` Vote account to be updated with the Pubkey for authorization
+    ///   1. `[]` Clock sysvar
+    ///   2. `[SIGNER]` Vote or withdraw authority
+    ///   3. `[SIGNER]` New vote or withdraw authority
+    AuthorizeChecked(VoteAuthorize),
+
+    /// Update the onchain vote state for the signer.
+    ///
+    /// # Account references
+    ///   0. `[Write]` Vote account to vote with
+    ///   1. `[SIGNER]` Vote authority
+    UpdateVoteState(VoteStateUpdate),
+
+    /// Update the onchain vote state for the signer along with a switching proof.
+    ///
+    /// # Account references
+    ///   0. `[Write]` Vote account to vote with
+    ///   1. `[SIGNER]` Vote authority
+    UpdateVoteStateSwitch(VoteStateUpdate, Hash),
+
+    /// Given that the current Voter or Withdrawer authority is a derived key,
+    /// this instruction allows someone who can sign for that derived key's
+    /// base key to authorize a new Voter or Withdrawer for a vote account.
+    ///
+    /// # Account references
+    ///   0. `[Write]` Vote account to be updated
+    ///   1. `[]` Clock sysvar
+    ///   2. `[SIGNER]` Base key of current Voter or Withdrawer authority's derived key
+    AuthorizeWithSeed(VoteAuthorizeWithSeedArgs),
+
+    /// Given that the current Voter or Withdrawer authority is a derived key,
+    /// this instruction allows someone who can sign for that derived key's
+    /// base key to authorize a new Voter or Withdrawer for a vote account.
+    ///
+    /// This instruction behaves like `AuthorizeWithSeed` with the additional requirement
+    /// that the new vote or withdraw authority must also be a signer.
+    ///
+    /// # Account references
+    ///   0. `[Write]` Vote account to be updated
+    ///   1. `[]` Clock sysvar
+    ///   2. `[SIGNER]` Base key of current Voter or Withdrawer authority's derived key
+    ///   3. `[SIGNER]` New vote or withdraw authority
+    AuthorizeCheckedWithSeed(VoteAuthorizeCheckedWithSeedArgs),
+
+    /// Update the onchain vote state for the signer.
+    ///
+    /// # Account references
+    ///   0. `[Write]` Vote account to vote with
+    ///   1. `[SIGNER]` Vote authority
+    #[cfg_attr(feature = "serde", serde(with = "serde_compact_vote_state_update"))]
+    CompactUpdateVoteState(VoteStateUpdate),
+
+    /// Update the onchain vote state for the signer along with a switching proof.
+    ///
+    /// # Account references
+    ///   0. `[Write]` Vote account to vote with
+    ///   1. `[SIGNER]` Vote authority
+    CompactUpdateVoteStateSwitch(
+        #[cfg_attr(feature = "serde", serde(with = "serde_compact_vote_state_update"))]
+        VoteStateUpdate,
+        Hash,
+    ),
+
+    /// Sync the onchain vote state with local tower
+    ///
+    /// # Account references
+    ///   0. `[Write]` Vote account to vote with
+    ///   1. `[SIGNER]` Vote authority
+    #[cfg_attr(feature = "serde", serde(with = "serde_tower_sync"))]
+    TowerSync(TowerSync),
+
+    /// Sync the onchain vote state with local tower along with a switching proof
+    ///
+    /// # Account references
+    ///   0. `[Write]` Vote account to vote with
+    ///   1. `[SIGNER]` Vote authority
+    TowerSyncSwitch(
+        #[cfg_attr(feature = "serde", serde(with = "serde_tower_sync"))] TowerSync,
+        Hash,
+    ),
+}
+
+impl VoteInstruction {
+    pub fn is_simple_vote(&self) -> bool {
+        matches!(
+            self,
+            Self::Vote(_)
+                | Self::VoteSwitch(_, _)
+                | Self::UpdateVoteState(_)
+                | Self::UpdateVoteStateSwitch(_, _)
+                | Self::CompactUpdateVoteState(_)
+                | Self::CompactUpdateVoteStateSwitch(_, _)
+                | Self::TowerSync(_)
+                | Self::TowerSyncSwitch(_, _),
+        )
+    }
+
+    pub fn is_single_vote_state_update(&self) -> bool {
+        matches!(
+            self,
+            Self::UpdateVoteState(_)
+                | Self::UpdateVoteStateSwitch(_, _)
+                | Self::CompactUpdateVoteState(_)
+                | Self::CompactUpdateVoteStateSwitch(_, _)
+                | Self::TowerSync(_)
+                | Self::TowerSyncSwitch(_, _),
+        )
+    }
+
+    /// Only to be used on vote instructions (guard with is_simple_vote),  panics otherwise
+    pub fn last_voted_slot(&self) -> Option<Slot> {
+        assert!(self.is_simple_vote());
+        match self {
+            Self::Vote(v) | Self::VoteSwitch(v, _) => v.last_voted_slot(),
+            Self::UpdateVoteState(vote_state_update)
+            | Self::UpdateVoteStateSwitch(vote_state_update, _)
+            | Self::CompactUpdateVoteState(vote_state_update)
+            | Self::CompactUpdateVoteStateSwitch(vote_state_update, _) => {
+                vote_state_update.last_voted_slot()
+            }
+            Self::TowerSync(tower_sync) | Self::TowerSyncSwitch(tower_sync, _) => {
+                tower_sync.last_voted_slot()
+            }
+            _ => panic!("Tried to get slot on non simple vote instruction"),
+        }
+    }
+
+    /// Only to be used on vote instructions (guard with is_simple_vote), panics otherwise
+    pub fn hash(&self) -> Hash {
+        assert!(self.is_simple_vote());
+        match self {
+            Self::Vote(v) | Self::VoteSwitch(v, _) => v.hash,
+            Self::UpdateVoteState(vote_state_update)
+            | Self::UpdateVoteStateSwitch(vote_state_update, _)
+            | Self::CompactUpdateVoteState(vote_state_update)
+            | Self::CompactUpdateVoteStateSwitch(vote_state_update, _) => vote_state_update.hash,
+            Self::TowerSync(tower_sync) | Self::TowerSyncSwitch(tower_sync, _) => tower_sync.hash,
+            _ => panic!("Tried to get hash on non simple vote instruction"),
+        }
+    }
+    /// Only to be used on vote instructions (guard with is_simple_vote),  panics otherwise
+    pub fn timestamp(&self) -> Option<UnixTimestamp> {
+        assert!(self.is_simple_vote());
+        match self {
+            Self::Vote(v) | Self::VoteSwitch(v, _) => v.timestamp,
+            Self::UpdateVoteState(vote_state_update)
+            | Self::UpdateVoteStateSwitch(vote_state_update, _)
+            | Self::CompactUpdateVoteState(vote_state_update)
+            | Self::CompactUpdateVoteStateSwitch(vote_state_update, _) => {
+                vote_state_update.timestamp
+            }
+            Self::TowerSync(tower_sync) | Self::TowerSyncSwitch(tower_sync, _) => {
+                tower_sync.timestamp
+            }
+            _ => panic!("Tried to get timestamp on non simple vote instruction"),
+        }
+    }
+}
+
+#[cfg(feature = "bincode")]
+fn initialize_account(vote_pubkey: &Pubkey, vote_init: &VoteInit) -> Instruction {
+    let account_metas = vec![
+        AccountMeta::new(*vote_pubkey, false),
+        AccountMeta::new_readonly(sysvar::rent::id(), false),
+        AccountMeta::new_readonly(sysvar::clock::id(), false),
+        AccountMeta::new_readonly(vote_init.node_pubkey, true),
+    ];
+
+    Instruction::new_with_bincode(
+        id(),
+        &VoteInstruction::InitializeAccount(*vote_init),
+        account_metas,
+    )
+}
+
+pub struct CreateVoteAccountConfig<'a> {
+    pub space: u64,
+    pub with_seed: Option<(&'a Pubkey, &'a str)>,
+}
+
+impl Default for CreateVoteAccountConfig<'_> {
+    fn default() -> Self {
+        Self {
+            space: VoteStateVersions::vote_state_size_of(false) as u64,
+            with_seed: None,
+        }
+    }
+}
+
+#[cfg(feature = "bincode")]
+pub fn create_account_with_config(
+    from_pubkey: &Pubkey,
+    vote_pubkey: &Pubkey,
+    vote_init: &VoteInit,
+    lamports: u64,
+    config: CreateVoteAccountConfig,
+) -> Vec<Instruction> {
+    let create_ix = if let Some((base, seed)) = config.with_seed {
+        solana_system_interface::instruction::create_account_with_seed(
+            from_pubkey,
+            vote_pubkey,
+            base,
+            seed,
+            lamports,
+            config.space,
+            &id(),
+        )
+    } else {
+        solana_system_interface::instruction::create_account(
+            from_pubkey,
+            vote_pubkey,
+            lamports,
+            config.space,
+            &id(),
+        )
+    };
+    let init_ix = initialize_account(vote_pubkey, vote_init);
+    vec![create_ix, init_ix]
+}
+
+#[cfg(feature = "bincode")]
+pub fn authorize(
+    vote_pubkey: &Pubkey,
+    authorized_pubkey: &Pubkey, // currently authorized
+    new_authorized_pubkey: &Pubkey,
+    vote_authorize: VoteAuthorize,
+) -> Instruction {
+    let account_metas = vec![
+        AccountMeta::new(*vote_pubkey, false),
+        AccountMeta::new_readonly(sysvar::clock::id(), false),
+        AccountMeta::new_readonly(*authorized_pubkey, true),
+    ];
+
+    Instruction::new_with_bincode(
+        id(),
+        &VoteInstruction::Authorize(*new_authorized_pubkey, vote_authorize),
+        account_metas,
+    )
+}
+
+#[cfg(feature = "bincode")]
+pub fn authorize_checked(
+    vote_pubkey: &Pubkey,
+    authorized_pubkey: &Pubkey, // currently authorized
+    new_authorized_pubkey: &Pubkey,
+    vote_authorize: VoteAuthorize,
+) -> Instruction {
+    let account_metas = vec![
+        AccountMeta::new(*vote_pubkey, false),
+        AccountMeta::new_readonly(sysvar::clock::id(), false),
+        AccountMeta::new_readonly(*authorized_pubkey, true),
+        AccountMeta::new_readonly(*new_authorized_pubkey, true),
+    ];
+
+    Instruction::new_with_bincode(
+        id(),
+        &VoteInstruction::AuthorizeChecked(vote_authorize),
+        account_metas,
+    )
+}
+
+#[cfg(feature = "bincode")]
+pub fn authorize_with_seed(
+    vote_pubkey: &Pubkey,
+    current_authority_base_key: &Pubkey,
+    current_authority_derived_key_owner: &Pubkey,
+    current_authority_derived_key_seed: &str,
+    new_authority: &Pubkey,
+    authorization_type: VoteAuthorize,
+) -> Instruction {
+    let account_metas = vec![
+        AccountMeta::new(*vote_pubkey, false),
+        AccountMeta::new_readonly(sysvar::clock::id(), false),
+        AccountMeta::new_readonly(*current_authority_base_key, true),
+    ];
+
+    Instruction::new_with_bincode(
+        id(),
+        &VoteInstruction::AuthorizeWithSeed(VoteAuthorizeWithSeedArgs {
+            authorization_type,
+            current_authority_derived_key_owner: *current_authority_derived_key_owner,
+            current_authority_derived_key_seed: current_authority_derived_key_seed.to_string(),
+            new_authority: *new_authority,
+        }),
+        account_metas,
+    )
+}
+
+#[cfg(feature = "bincode")]
+pub fn authorize_checked_with_seed(
+    vote_pubkey: &Pubkey,
+    current_authority_base_key: &Pubkey,
+    current_authority_derived_key_owner: &Pubkey,
+    current_authority_derived_key_seed: &str,
+    new_authority: &Pubkey,
+    authorization_type: VoteAuthorize,
+) -> Instruction {
+    let account_metas = vec![
+        AccountMeta::new(*vote_pubkey, false),
+        AccountMeta::new_readonly(sysvar::clock::id(), false),
+        AccountMeta::new_readonly(*current_authority_base_key, true),
+        AccountMeta::new_readonly(*new_authority, true),
+    ];
+
+    Instruction::new_with_bincode(
+        id(),
+        &VoteInstruction::AuthorizeCheckedWithSeed(VoteAuthorizeCheckedWithSeedArgs {
+            authorization_type,
+            current_authority_derived_key_owner: *current_authority_derived_key_owner,
+            current_authority_derived_key_seed: current_authority_derived_key_seed.to_string(),
+        }),
+        account_metas,
+    )
+}
+
+#[cfg(feature = "bincode")]
+pub fn update_validator_identity(
+    vote_pubkey: &Pubkey,
+    authorized_withdrawer_pubkey: &Pubkey,
+    node_pubkey: &Pubkey,
+) -> Instruction {
+    let account_metas = vec![
+        AccountMeta::new(*vote_pubkey, false),
+        AccountMeta::new_readonly(*node_pubkey, true),
+        AccountMeta::new_readonly(*authorized_withdrawer_pubkey, true),
+    ];
+
+    Instruction::new_with_bincode(
+        id(),
+        &VoteInstruction::UpdateValidatorIdentity,
+        account_metas,
+    )
+}
+
+#[cfg(feature = "bincode")]
+pub fn update_commission(
+    vote_pubkey: &Pubkey,
+    authorized_withdrawer_pubkey: &Pubkey,
+    commission: u8,
+) -> Instruction {
+    let account_metas = vec![
+        AccountMeta::new(*vote_pubkey, false),
+        AccountMeta::new_readonly(*authorized_withdrawer_pubkey, true),
+    ];
+
+    Instruction::new_with_bincode(
+        id(),
+        &VoteInstruction::UpdateCommission(commission),
+        account_metas,
+    )
+}
+
+#[cfg(feature = "bincode")]
+pub fn vote(vote_pubkey: &Pubkey, authorized_voter_pubkey: &Pubkey, vote: Vote) -> Instruction {
+    let account_metas = vec![
+        AccountMeta::new(*vote_pubkey, false),
+        AccountMeta::new_readonly(sysvar::slot_hashes::id(), false),
+        AccountMeta::new_readonly(sysvar::clock::id(), false),
+        AccountMeta::new_readonly(*authorized_voter_pubkey, true),
+    ];
+
+    Instruction::new_with_bincode(id(), &VoteInstruction::Vote(vote), account_metas)
+}
+
+#[cfg(feature = "bincode")]
+pub fn vote_switch(
+    vote_pubkey: &Pubkey,
+    authorized_voter_pubkey: &Pubkey,
+    vote: Vote,
+    proof_hash: Hash,
+) -> Instruction {
+    let account_metas = vec![
+        AccountMeta::new(*vote_pubkey, false),
+        AccountMeta::new_readonly(sysvar::slot_hashes::id(), false),
+        AccountMeta::new_readonly(sysvar::clock::id(), false),
+        AccountMeta::new_readonly(*authorized_voter_pubkey, true),
+    ];
+
+    Instruction::new_with_bincode(
+        id(),
+        &VoteInstruction::VoteSwitch(vote, proof_hash),
+        account_metas,
+    )
+}
+
+#[cfg(feature = "bincode")]
+pub fn update_vote_state(
+    vote_pubkey: &Pubkey,
+    authorized_voter_pubkey: &Pubkey,
+    vote_state_update: VoteStateUpdate,
+) -> Instruction {
+    let account_metas = vec![
+        AccountMeta::new(*vote_pubkey, false),
+        AccountMeta::new_readonly(*authorized_voter_pubkey, true),
+    ];
+
+    Instruction::new_with_bincode(
+        id(),
+        &VoteInstruction::UpdateVoteState(vote_state_update),
+        account_metas,
+    )
+}
+
+#[cfg(feature = "bincode")]
+pub fn update_vote_state_switch(
+    vote_pubkey: &Pubkey,
+    authorized_voter_pubkey: &Pubkey,
+    vote_state_update: VoteStateUpdate,
+    proof_hash: Hash,
+) -> Instruction {
+    let account_metas = vec![
+        AccountMeta::new(*vote_pubkey, false),
+        AccountMeta::new_readonly(*authorized_voter_pubkey, true),
+    ];
+
+    Instruction::new_with_bincode(
+        id(),
+        &VoteInstruction::UpdateVoteStateSwitch(vote_state_update, proof_hash),
+        account_metas,
+    )
+}
+
+#[cfg(feature = "bincode")]
+pub fn compact_update_vote_state(
+    vote_pubkey: &Pubkey,
+    authorized_voter_pubkey: &Pubkey,
+    vote_state_update: VoteStateUpdate,
+) -> Instruction {
+    let account_metas = vec![
+        AccountMeta::new(*vote_pubkey, false),
+        AccountMeta::new_readonly(*authorized_voter_pubkey, true),
+    ];
+
+    Instruction::new_with_bincode(
+        id(),
+        &VoteInstruction::CompactUpdateVoteState(vote_state_update),
+        account_metas,
+    )
+}
+
+#[cfg(feature = "bincode")]
+pub fn compact_update_vote_state_switch(
+    vote_pubkey: &Pubkey,
+    authorized_voter_pubkey: &Pubkey,
+    vote_state_update: VoteStateUpdate,
+    proof_hash: Hash,
+) -> Instruction {
+    let account_metas = vec![
+        AccountMeta::new(*vote_pubkey, false),
+        AccountMeta::new_readonly(*authorized_voter_pubkey, true),
+    ];
+
+    Instruction::new_with_bincode(
+        id(),
+        &VoteInstruction::CompactUpdateVoteStateSwitch(vote_state_update, proof_hash),
+        account_metas,
+    )
+}
+
+#[cfg(feature = "bincode")]
+pub fn tower_sync(
+    vote_pubkey: &Pubkey,
+    authorized_voter_pubkey: &Pubkey,
+    tower_sync: TowerSync,
+) -> Instruction {
+    let account_metas = vec![
+        AccountMeta::new(*vote_pubkey, false),
+        AccountMeta::new_readonly(*authorized_voter_pubkey, true),
+    ];
+
+    Instruction::new_with_bincode(id(), &VoteInstruction::TowerSync(tower_sync), account_metas)
+}
+
+#[cfg(feature = "bincode")]
+pub fn tower_sync_switch(
+    vote_pubkey: &Pubkey,
+    authorized_voter_pubkey: &Pubkey,
+    tower_sync: TowerSync,
+    proof_hash: Hash,
+) -> Instruction {
+    let account_metas = vec![
+        AccountMeta::new(*vote_pubkey, false),
+        AccountMeta::new_readonly(*authorized_voter_pubkey, true),
+    ];
+
+    Instruction::new_with_bincode(
+        id(),
+        &VoteInstruction::TowerSyncSwitch(tower_sync, proof_hash),
+        account_metas,
+    )
+}
+
+#[cfg(feature = "bincode")]
+pub fn withdraw(
+    vote_pubkey: &Pubkey,
+    authorized_withdrawer_pubkey: &Pubkey,
+    lamports: u64,
+    to_pubkey: &Pubkey,
+) -> Instruction {
+    let account_metas = vec![
+        AccountMeta::new(*vote_pubkey, false),
+        AccountMeta::new(*to_pubkey, false),
+        AccountMeta::new_readonly(*authorized_withdrawer_pubkey, true),
+    ];
+
+    Instruction::new_with_bincode(id(), &VoteInstruction::Withdraw(lamports), account_metas)
+}
diff --git a/vote-interface/src/lib.rs b/vote-interface/src/lib.rs
new file mode 100644
index 0000000000..1826ed54a3
--- /dev/null
+++ b/vote-interface/src/lib.rs
@@ -0,0 +1,14 @@
+#![cfg_attr(docsrs, feature(doc_auto_cfg))]
+#![cfg_attr(feature = "frozen-abi", feature(min_specialization))]
+//! The [vote native program][np].
+//!
+//! [np]: https://docs.solanalabs.com/runtime/programs#vote-program
+
+pub mod authorized_voters;
+pub mod error;
+pub mod instruction;
+pub mod state;
+
+pub mod program {
+    pub use solana_sdk_ids::vote::{check_id, id, ID};
+}
diff --git a/vote-interface/src/state/mod.rs b/vote-interface/src/state/mod.rs
new file mode 100644
index 0000000000..06e2c727f0
--- /dev/null
+++ b/vote-interface/src/state/mod.rs
@@ -0,0 +1,1046 @@
+//! Vote state
+
+#[cfg(feature = "dev-context-only-utils")]
+use arbitrary::Arbitrary;
+#[cfg(feature = "serde")]
+use serde_derive::{Deserialize, Serialize};
+#[cfg(feature = "frozen-abi")]
+use solana_frozen_abi_macro::AbiExample;
+use {
+    crate::authorized_voters::AuthorizedVoters,
+    solana_clock::{Epoch, Slot, UnixTimestamp},
+    solana_pubkey::Pubkey,
+    solana_rent::Rent,
+    std::{collections::VecDeque, fmt::Debug},
+};
+#[cfg(test)]
+use {arbitrary::Unstructured, solana_epoch_schedule::MAX_LEADER_SCHEDULE_EPOCH_OFFSET};
+
+mod vote_state_0_23_5;
+pub mod vote_state_1_14_11;
+pub use vote_state_1_14_11::*;
+pub mod vote_state_versions;
+pub use vote_state_versions::*;
+pub mod vote_state_v3;
+pub use vote_state_v3::VoteStateV3;
+pub mod vote_state_v4;
+pub use vote_state_v4::VoteStateV4;
+mod vote_instruction_data;
+pub use vote_instruction_data::*;
+#[cfg(any(target_os = "solana", feature = "bincode"))]
+pub(crate) mod vote_state_deserialize;
+
+/// Size of a BLS public key in a compressed point representation
+pub const BLS_PUBLIC_KEY_COMPRESSED_SIZE: usize = 48;
+
+// Maximum number of votes to keep around, tightly coupled with epoch_schedule::MINIMUM_SLOTS_PER_EPOCH
+pub const MAX_LOCKOUT_HISTORY: usize = 31;
+pub const INITIAL_LOCKOUT: usize = 2;
+
+// Maximum number of credits history to keep around
+pub const MAX_EPOCH_CREDITS_HISTORY: usize = 64;
+
+// Offset of VoteState::prior_voters, for determining initialization status without deserialization
+const DEFAULT_PRIOR_VOTERS_OFFSET: usize = 114;
+
+// Number of slots of grace period for which maximum vote credits are awarded - votes landing within this number of slots of the slot that is being voted on are awarded full credits.
+pub const VOTE_CREDITS_GRACE_SLOTS: u8 = 2;
+
+// Maximum number of credits to award for a vote; this number of credits is awarded to votes on slots that land within the grace period. After that grace period, vote credits are reduced.
+pub const VOTE_CREDITS_MAXIMUM_PER_SLOT: u8 = 16;
+
+#[cfg_attr(feature = "frozen-abi", derive(AbiExample))]
+#[cfg_attr(feature = "serde", derive(Deserialize, Serialize))]
+#[derive(Default, Debug, PartialEq, Eq, Copy, Clone)]
+#[cfg_attr(feature = "dev-context-only-utils", derive(Arbitrary))]
+pub struct Lockout {
+    slot: Slot,
+    confirmation_count: u32,
+}
+
+impl Lockout {
+    pub fn new(slot: Slot) -> Self {
+        Self::new_with_confirmation_count(slot, 1)
+    }
+
+    pub fn new_with_confirmation_count(slot: Slot, confirmation_count: u32) -> Self {
+        Self {
+            slot,
+            confirmation_count,
+        }
+    }
+
+    // The number of slots for which this vote is locked
+    pub fn lockout(&self) -> u64 {
+        (INITIAL_LOCKOUT as u64).wrapping_pow(std::cmp::min(
+            self.confirmation_count(),
+            MAX_LOCKOUT_HISTORY as u32,
+        ))
+    }
+
+    // The last slot at which a vote is still locked out. Validators should not
+    // vote on a slot in another fork which is less than or equal to this slot
+    // to avoid having their stake slashed.
+    pub fn last_locked_out_slot(&self) -> Slot {
+        self.slot.saturating_add(self.lockout())
+    }
+
+    pub fn is_locked_out_at_slot(&self, slot: Slot) -> bool {
+        self.last_locked_out_slot() >= slot
+    }
+
+    pub fn slot(&self) -> Slot {
+        self.slot
+    }
+
+    pub fn confirmation_count(&self) -> u32 {
+        self.confirmation_count
+    }
+
+    pub fn increase_confirmation_count(&mut self, by: u32) {
+        self.confirmation_count = self.confirmation_count.saturating_add(by)
+    }
+}
+
+#[cfg_attr(feature = "frozen-abi", derive(AbiExample))]
+#[cfg_attr(feature = "serde", derive(Deserialize, Serialize))]
+#[derive(Default, Debug, PartialEq, Eq, Copy, Clone)]
+#[cfg_attr(feature = "dev-context-only-utils", derive(Arbitrary))]
+pub struct LandedVote {
+    // Latency is the difference in slot number between the slot that was voted on (lockout.slot) and the slot in
+    // which the vote that added this Lockout landed.  For votes which were cast before versions of the validator
+    // software which recorded vote latencies, latency is recorded as 0.
+    pub latency: u8,
+    pub lockout: Lockout,
+}
+
+impl LandedVote {
+    pub fn slot(&self) -> Slot {
+        self.lockout.slot
+    }
+
+    pub fn confirmation_count(&self) -> u32 {
+        self.lockout.confirmation_count
+    }
+}
+
+impl From<LandedVote> for Lockout {
+    fn from(landed_vote: LandedVote) -> Self {
+        landed_vote.lockout
+    }
+}
+
+impl From<Lockout> for LandedVote {
+    fn from(lockout: Lockout) -> Self {
+        Self {
+            latency: 0,
+            lockout,
+        }
+    }
+}
+
+#[cfg_attr(feature = "frozen-abi", derive(AbiExample))]
+#[cfg_attr(feature = "serde", derive(Deserialize, Serialize))]
+#[derive(Debug, Default, PartialEq, Eq, Clone)]
+#[cfg_attr(feature = "dev-context-only-utils", derive(Arbitrary))]
+pub struct BlockTimestamp {
+    pub slot: Slot,
+    pub timestamp: UnixTimestamp,
+}
+
+// this is how many epochs a voter can be remembered for slashing
+const MAX_ITEMS: usize = 32;
+
+#[cfg_attr(feature = "serde", derive(Deserialize, Serialize))]
+#[cfg_attr(feature = "frozen-abi", derive(AbiExample))]
+#[derive(Debug, PartialEq, Eq, Clone)]
+#[cfg_attr(feature = "dev-context-only-utils", derive(Arbitrary))]
+pub struct CircBuf<I> {
+    buf: [I; MAX_ITEMS],
+    /// next pointer
+    idx: usize,
+    is_empty: bool,
+}
+
+impl<I: Default + Copy> Default for CircBuf<I> {
+    fn default() -> Self {
+        Self {
+            buf: [I::default(); MAX_ITEMS],
+            idx: MAX_ITEMS
+                .checked_sub(1)
+                .expect("`MAX_ITEMS` should be positive"),
+            is_empty: true,
+        }
+    }
+}
+
+impl<I> CircBuf<I> {
+    pub fn append(&mut self, item: I) {
+        // remember prior delegate and when we switched, to support later slashing
+        self.idx = self
+            .idx
+            .checked_add(1)
+            .and_then(|idx| idx.checked_rem(MAX_ITEMS))
+            .expect("`self.idx` should be < `MAX_ITEMS` which should be non-zero");
+
+        self.buf[self.idx] = item;
+        self.is_empty = false;
+    }
+
+    pub fn buf(&self) -> &[I; MAX_ITEMS] {
+        &self.buf
+    }
+
+    pub fn last(&self) -> Option<&I> {
+        if !self.is_empty {
+            self.buf.get(self.idx)
+        } else {
+            None
+        }
+    }
+}
+
+#[cfg(feature = "serde")]
+pub mod serde_compact_vote_state_update {
+    use {
+        super::*,
+        crate::state::Lockout,
+        serde::{Deserialize, Deserializer, Serialize, Serializer},
+        solana_hash::Hash,
+        solana_serde_varint as serde_varint, solana_short_vec as short_vec,
+    };
+
+    #[cfg_attr(feature = "frozen-abi", derive(AbiExample))]
+    #[derive(serde_derive::Deserialize, serde_derive::Serialize)]
+    struct LockoutOffset {
+        #[serde(with = "serde_varint")]
+        offset: Slot,
+        confirmation_count: u8,
+    }
+
+    #[derive(serde_derive::Deserialize, serde_derive::Serialize)]
+    struct CompactVoteStateUpdate {
+        root: Slot,
+        #[serde(with = "short_vec")]
+        lockout_offsets: Vec<LockoutOffset>,
+        hash: Hash,
+        timestamp: Option<UnixTimestamp>,
+    }
+
+    pub fn serialize<S>(
+        vote_state_update: &VoteStateUpdate,
+        serializer: S,
+    ) -> Result<S::Ok, S::Error>
+    where
+        S: Serializer,
+    {
+        let lockout_offsets = vote_state_update.lockouts.iter().scan(
+            vote_state_update.root.unwrap_or_default(),
+            |slot, lockout| {
+                let Some(offset) = lockout.slot().checked_sub(*slot) else {
+                    return Some(Err(serde::ser::Error::custom("Invalid vote lockout")));
+                };
+                let Ok(confirmation_count) = u8::try_from(lockout.confirmation_count()) else {
+                    return Some(Err(serde::ser::Error::custom("Invalid confirmation count")));
+                };
+                let lockout_offset = LockoutOffset {
+                    offset,
+                    confirmation_count,
+                };
+                *slot = lockout.slot();
+                Some(Ok(lockout_offset))
+            },
+        );
+        let compact_vote_state_update = CompactVoteStateUpdate {
+            root: vote_state_update.root.unwrap_or(Slot::MAX),
+            lockout_offsets: lockout_offsets.collect::<Result<_, _>>()?,
+            hash: vote_state_update.hash,
+            timestamp: vote_state_update.timestamp,
+        };
+        compact_vote_state_update.serialize(serializer)
+    }
+
+    pub fn deserialize<'de, D>(deserializer: D) -> Result<VoteStateUpdate, D::Error>
+    where
+        D: Deserializer<'de>,
+    {
+        let CompactVoteStateUpdate {
+            root,
+            lockout_offsets,
+            hash,
+            timestamp,
+        } = CompactVoteStateUpdate::deserialize(deserializer)?;
+        let root = (root != Slot::MAX).then_some(root);
+        let lockouts =
+            lockout_offsets
+                .iter()
+                .scan(root.unwrap_or_default(), |slot, lockout_offset| {
+                    *slot = match slot.checked_add(lockout_offset.offset) {
+                        None => {
+                            return Some(Err(serde::de::Error::custom("Invalid lockout offset")))
+                        }
+                        Some(slot) => slot,
+                    };
+                    let lockout = Lockout::new_with_confirmation_count(
+                        *slot,
+                        u32::from(lockout_offset.confirmation_count),
+                    );
+                    Some(Ok(lockout))
+                });
+        Ok(VoteStateUpdate {
+            root,
+            lockouts: lockouts.collect::<Result<_, _>>()?,
+            hash,
+            timestamp,
+        })
+    }
+}
+
+#[cfg(feature = "serde")]
+pub mod serde_tower_sync {
+    use {
+        super::*,
+        crate::state::Lockout,
+        serde::{Deserialize, Deserializer, Serialize, Serializer},
+        solana_hash::Hash,
+        solana_serde_varint as serde_varint, solana_short_vec as short_vec,
+    };
+
+    #[cfg_attr(feature = "frozen-abi", derive(AbiExample))]
+    #[derive(serde_derive::Deserialize, serde_derive::Serialize)]
+    struct LockoutOffset {
+        #[serde(with = "serde_varint")]
+        offset: Slot,
+        confirmation_count: u8,
+    }
+
+    #[derive(serde_derive::Deserialize, serde_derive::Serialize)]
+    struct CompactTowerSync {
+        root: Slot,
+        #[serde(with = "short_vec")]
+        lockout_offsets: Vec<LockoutOffset>,
+        hash: Hash,
+        timestamp: Option<UnixTimestamp>,
+        block_id: Hash,
+    }
+
+    pub fn serialize<S>(tower_sync: &TowerSync, serializer: S) -> Result<S::Ok, S::Error>
+    where
+        S: Serializer,
+    {
+        let lockout_offsets = tower_sync.lockouts.iter().scan(
+            tower_sync.root.unwrap_or_default(),
+            |slot, lockout| {
+                let Some(offset) = lockout.slot().checked_sub(*slot) else {
+                    return Some(Err(serde::ser::Error::custom("Invalid vote lockout")));
+                };
+                let Ok(confirmation_count) = u8::try_from(lockout.confirmation_count()) else {
+                    return Some(Err(serde::ser::Error::custom("Invalid confirmation count")));
+                };
+                let lockout_offset = LockoutOffset {
+                    offset,
+                    confirmation_count,
+                };
+                *slot = lockout.slot();
+                Some(Ok(lockout_offset))
+            },
+        );
+        let compact_tower_sync = CompactTowerSync {
+            root: tower_sync.root.unwrap_or(Slot::MAX),
+            lockout_offsets: lockout_offsets.collect::<Result<_, _>>()?,
+            hash: tower_sync.hash,
+            timestamp: tower_sync.timestamp,
+            block_id: tower_sync.block_id,
+        };
+        compact_tower_sync.serialize(serializer)
+    }
+
+    pub fn deserialize<'de, D>(deserializer: D) -> Result<TowerSync, D::Error>
+    where
+        D: Deserializer<'de>,
+    {
+        let CompactTowerSync {
+            root,
+            lockout_offsets,
+            hash,
+            timestamp,
+            block_id,
+        } = CompactTowerSync::deserialize(deserializer)?;
+        let root = (root != Slot::MAX).then_some(root);
+        let lockouts =
+            lockout_offsets
+                .iter()
+                .scan(root.unwrap_or_default(), |slot, lockout_offset| {
+                    *slot = match slot.checked_add(lockout_offset.offset) {
+                        None => {
+                            return Some(Err(serde::de::Error::custom("Invalid lockout offset")))
+                        }
+                        Some(slot) => slot,
+                    };
+                    let lockout = Lockout::new_with_confirmation_count(
+                        *slot,
+                        u32::from(lockout_offset.confirmation_count),
+                    );
+                    Some(Ok(lockout))
+                });
+        Ok(TowerSync {
+            root,
+            lockouts: lockouts.collect::<Result<_, _>>()?,
+            hash,
+            timestamp,
+            block_id,
+        })
+    }
+}
+
+#[cfg(test)]
+mod tests {
+    use {
+        super::*, crate::error::VoteError, bincode::serialized_size, core::mem::MaybeUninit,
+        itertools::Itertools, rand::Rng, solana_clock::Clock, solana_hash::Hash,
+        solana_instruction_error::InstructionError,
+    };
+
+    #[test]
+    fn test_vote_serialize() {
+        let mut buffer: Vec<u8> = vec![0; VoteStateV3::size_of()];
+        let mut vote_state = VoteStateV3::default();
+        vote_state
+            .votes
+            .resize(MAX_LOCKOUT_HISTORY, LandedVote::default());
+        vote_state.root_slot = Some(1);
+        let versioned = VoteStateVersions::new_v3(vote_state);
+        assert!(VoteStateV3::serialize(&versioned, &mut buffer[0..4]).is_err());
+        VoteStateV3::serialize(&versioned, &mut buffer).unwrap();
+        assert_eq!(
+            VoteStateV3::deserialize(&buffer).unwrap(),
+            versioned.convert_to_v3()
+        );
+    }
+
+    #[test]
+    fn test_vote_deserialize_into() {
+        // base case
+        let target_vote_state = VoteStateV3::default();
+        let vote_state_buf =
+            bincode::serialize(&VoteStateVersions::new_v3(target_vote_state.clone())).unwrap();
+
+        let mut test_vote_state = VoteStateV3::default();
+        VoteStateV3::deserialize_into(&vote_state_buf, &mut test_vote_state).unwrap();
+
+        assert_eq!(target_vote_state, test_vote_state);
+
+        // variant
+        // provide 4x the minimum struct size in bytes to ensure we typically touch every field
+        let struct_bytes_x4 = std::mem::size_of::<VoteStateV3>() * 4;
+        for _ in 0..1000 {
+            let raw_data: Vec<u8> = (0..struct_bytes_x4).map(|_| rand::random::<u8>()).collect();
+            let mut unstructured = Unstructured::new(&raw_data);
+
+            let target_vote_state_versions =
+                VoteStateVersions::arbitrary(&mut unstructured).unwrap();
+            let vote_state_buf = bincode::serialize(&target_vote_state_versions).unwrap();
+            let target_vote_state = target_vote_state_versions.convert_to_v3();
+
+            let mut test_vote_state = VoteStateV3::default();
+            VoteStateV3::deserialize_into(&vote_state_buf, &mut test_vote_state).unwrap();
+
+            assert_eq!(target_vote_state, test_vote_state);
+        }
+    }
+
+    #[test]
+    fn test_vote_deserialize_into_error() {
+        let target_vote_state = VoteStateV3::new_rand_for_tests(Pubkey::new_unique(), 42);
+        let mut vote_state_buf =
+            bincode::serialize(&VoteStateVersions::new_v3(target_vote_state.clone())).unwrap();
+        let len = vote_state_buf.len();
+        vote_state_buf.truncate(len - 1);
+
+        let mut test_vote_state = VoteStateV3::default();
+        VoteStateV3::deserialize_into(&vote_state_buf, &mut test_vote_state).unwrap_err();
+        assert_eq!(test_vote_state, VoteStateV3::default());
+    }
+
+    #[test]
+    fn test_vote_deserialize_into_uninit() {
+        // base case
+        let target_vote_state = VoteStateV3::default();
+        let vote_state_buf =
+            bincode::serialize(&VoteStateVersions::new_v3(target_vote_state.clone())).unwrap();
+
+        let mut test_vote_state = MaybeUninit::uninit();
+        VoteStateV3::deserialize_into_uninit(&vote_state_buf, &mut test_vote_state).unwrap();
+        let test_vote_state = unsafe { test_vote_state.assume_init() };
+
+        assert_eq!(target_vote_state, test_vote_state);
+
+        // variant
+        // provide 4x the minimum struct size in bytes to ensure we typically touch every field
+        let struct_bytes_x4 = std::mem::size_of::<VoteStateV3>() * 4;
+        for _ in 0..1000 {
+            let raw_data: Vec<u8> = (0..struct_bytes_x4).map(|_| rand::random::<u8>()).collect();
+            let mut unstructured = Unstructured::new(&raw_data);
+
+            let target_vote_state_versions =
+                VoteStateVersions::arbitrary(&mut unstructured).unwrap();
+            let vote_state_buf = bincode::serialize(&target_vote_state_versions).unwrap();
+            let target_vote_state = target_vote_state_versions.convert_to_v3();
+
+            let mut test_vote_state = MaybeUninit::uninit();
+            VoteStateV3::deserialize_into_uninit(&vote_state_buf, &mut test_vote_state).unwrap();
+            let test_vote_state = unsafe { test_vote_state.assume_init() };
+
+            assert_eq!(target_vote_state, test_vote_state);
+        }
+    }
+
+    #[test]
+    fn test_vote_deserialize_into_uninit_nopanic() {
+        // base case
+        let mut test_vote_state = MaybeUninit::uninit();
+        let e = VoteStateV3::deserialize_into_uninit(&[], &mut test_vote_state).unwrap_err();
+        assert_eq!(e, InstructionError::InvalidAccountData);
+
+        // variant
+        let serialized_len_x4 = serialized_size(&VoteStateV3::default()).unwrap() * 4;
+        let mut rng = rand::thread_rng();
+        for _ in 0..1000 {
+            let raw_data_length = rng.gen_range(1..serialized_len_x4);
+            let mut raw_data: Vec<u8> = (0..raw_data_length).map(|_| rng.gen::<u8>()).collect();
+
+            // pure random data will ~never have a valid enum tag, so lets help it out
+            if raw_data_length >= 4 && rng.gen::<bool>() {
+                let tag = rng.gen::<u8>() % 3;
+                raw_data[0] = tag;
+                raw_data[1] = 0;
+                raw_data[2] = 0;
+                raw_data[3] = 0;
+            }
+
+            // it is extremely improbable, though theoretically possible, for random bytes to be syntactically valid
+            // so we only check that the parser does not panic and that it succeeds or fails exactly in line with bincode
+            let mut test_vote_state = MaybeUninit::uninit();
+            let test_res = VoteStateV3::deserialize_into_uninit(&raw_data, &mut test_vote_state);
+            let bincode_res = bincode::deserialize::<VoteStateVersions>(&raw_data)
+                .map(|versioned| versioned.convert_to_v3());
+
+            if test_res.is_err() {
+                assert!(bincode_res.is_err());
+            } else {
+                let test_vote_state = unsafe { test_vote_state.assume_init() };
+                assert_eq!(test_vote_state, bincode_res.unwrap());
+            }
+        }
+    }
+
+    #[test]
+    fn test_vote_deserialize_into_uninit_ill_sized() {
+        // provide 4x the minimum struct size in bytes to ensure we typically touch every field
+        let struct_bytes_x4 = std::mem::size_of::<VoteStateV3>() * 4;
+        for _ in 0..1000 {
+            let raw_data: Vec<u8> = (0..struct_bytes_x4).map(|_| rand::random::<u8>()).collect();
+            let mut unstructured = Unstructured::new(&raw_data);
+
+            let original_vote_state_versions =
+                VoteStateVersions::arbitrary(&mut unstructured).unwrap();
+            let original_buf = bincode::serialize(&original_vote_state_versions).unwrap();
+
+            let mut truncated_buf = original_buf.clone();
+            let mut expanded_buf = original_buf.clone();
+
+            truncated_buf.resize(original_buf.len() - 8, 0);
+            expanded_buf.resize(original_buf.len() + 8, 0);
+
+            // truncated fails
+            let mut test_vote_state = MaybeUninit::uninit();
+            let test_res =
+                VoteStateV3::deserialize_into_uninit(&truncated_buf, &mut test_vote_state);
+            let bincode_res = bincode::deserialize::<VoteStateVersions>(&truncated_buf)
+                .map(|versioned| versioned.convert_to_v3());
+
+            assert!(test_res.is_err());
+            assert!(bincode_res.is_err());
+
+            // expanded succeeds
+            let mut test_vote_state = MaybeUninit::uninit();
+            VoteStateV3::deserialize_into_uninit(&expanded_buf, &mut test_vote_state).unwrap();
+            let bincode_res = bincode::deserialize::<VoteStateVersions>(&expanded_buf)
+                .map(|versioned| versioned.convert_to_v3());
+
+            let test_vote_state = unsafe { test_vote_state.assume_init() };
+            assert_eq!(test_vote_state, bincode_res.unwrap());
+        }
+    }
+
+    #[test]
+    fn test_vote_state_epoch_credits() {
+        let mut vote_state = VoteStateV3::default();
+
+        assert_eq!(vote_state.credits(), 0);
+        assert_eq!(vote_state.epoch_credits().clone(), vec![]);
+
+        let mut expected = vec![];
+        let mut credits = 0;
+        let epochs = (MAX_EPOCH_CREDITS_HISTORY + 2) as u64;
+        for epoch in 0..epochs {
+            for _j in 0..epoch {
+                vote_state.increment_credits(epoch, 1);
+                credits += 1;
+            }
+            expected.push((epoch, credits, credits - epoch));
+        }
+
+        while expected.len() > MAX_EPOCH_CREDITS_HISTORY {
+            expected.remove(0);
+        }
+
+        assert_eq!(vote_state.credits(), credits);
+        assert_eq!(vote_state.epoch_credits().clone(), expected);
+    }
+
+    #[test]
+    fn test_vote_state_epoch0_no_credits() {
+        let mut vote_state = VoteStateV3::default();
+
+        assert_eq!(vote_state.epoch_credits().len(), 0);
+        vote_state.increment_credits(1, 1);
+        assert_eq!(vote_state.epoch_credits().len(), 1);
+
+        vote_state.increment_credits(2, 1);
+        assert_eq!(vote_state.epoch_credits().len(), 2);
+    }
+
+    #[test]
+    fn test_vote_state_increment_credits() {
+        let mut vote_state = VoteStateV3::default();
+
+        let credits = (MAX_EPOCH_CREDITS_HISTORY + 2) as u64;
+        for i in 0..credits {
+            vote_state.increment_credits(i, 1);
+        }
+        assert_eq!(vote_state.credits(), credits);
+        assert!(vote_state.epoch_credits().len() <= MAX_EPOCH_CREDITS_HISTORY);
+    }
+
+    #[test]
+    fn test_vote_process_timestamp() {
+        let (slot, timestamp) = (15, 1_575_412_285);
+        let mut vote_state = VoteStateV3 {
+            last_timestamp: BlockTimestamp { slot, timestamp },
+            ..VoteStateV3::default()
+        };
+
+        assert_eq!(
+            vote_state.process_timestamp(slot - 1, timestamp + 1),
+            Err(VoteError::TimestampTooOld)
+        );
+        assert_eq!(
+            vote_state.last_timestamp,
+            BlockTimestamp { slot, timestamp }
+        );
+        assert_eq!(
+            vote_state.process_timestamp(slot + 1, timestamp - 1),
+            Err(VoteError::TimestampTooOld)
+        );
+        assert_eq!(
+            vote_state.process_timestamp(slot, timestamp + 1),
+            Err(VoteError::TimestampTooOld)
+        );
+        assert_eq!(vote_state.process_timestamp(slot, timestamp), Ok(()));
+        assert_eq!(
+            vote_state.last_timestamp,
+            BlockTimestamp { slot, timestamp }
+        );
+        assert_eq!(vote_state.process_timestamp(slot + 1, timestamp), Ok(()));
+        assert_eq!(
+            vote_state.last_timestamp,
+            BlockTimestamp {
+                slot: slot + 1,
+                timestamp
+            }
+        );
+        assert_eq!(
+            vote_state.process_timestamp(slot + 2, timestamp + 1),
+            Ok(())
+        );
+        assert_eq!(
+            vote_state.last_timestamp,
+            BlockTimestamp {
+                slot: slot + 2,
+                timestamp: timestamp + 1
+            }
+        );
+
+        // Test initial vote
+        vote_state.last_timestamp = BlockTimestamp::default();
+        assert_eq!(vote_state.process_timestamp(0, timestamp), Ok(()));
+    }
+
+    #[test]
+    fn test_get_and_update_authorized_voter() {
+        let original_voter = Pubkey::new_unique();
+        let mut vote_state = VoteStateV3::new(
+            &VoteInit {
+                node_pubkey: original_voter,
+                authorized_voter: original_voter,
+                authorized_withdrawer: original_voter,
+                commission: 0,
+            },
+            &Clock::default(),
+        );
+
+        assert_eq!(vote_state.authorized_voters.len(), 1);
+        assert_eq!(
+            *vote_state.authorized_voters.first().unwrap().1,
+            original_voter
+        );
+
+        // If no new authorized voter was set, the same authorized voter
+        // is locked into the next epoch
+        assert_eq!(
+            vote_state.get_and_update_authorized_voter(1).unwrap(),
+            original_voter
+        );
+
+        // Try to get the authorized voter for epoch 5, implies
+        // the authorized voter for epochs 1-4 were unchanged
+        assert_eq!(
+            vote_state.get_and_update_authorized_voter(5).unwrap(),
+            original_voter
+        );
+
+        // Authorized voter for expired epoch 0..5 should have been
+        // purged and no longer queryable
+        assert_eq!(vote_state.authorized_voters.len(), 1);
+        for i in 0..5 {
+            assert!(vote_state
+                .authorized_voters
+                .get_authorized_voter(i)
+                .is_none());
+        }
+
+        // Set an authorized voter change at slot 7
+        let new_authorized_voter = Pubkey::new_unique();
+        vote_state
+            .set_new_authorized_voter(&new_authorized_voter, 5, 7, |_| Ok(()))
+            .unwrap();
+
+        // Try to get the authorized voter for epoch 6, unchanged
+        assert_eq!(
+            vote_state.get_and_update_authorized_voter(6).unwrap(),
+            original_voter
+        );
+
+        // Try to get the authorized voter for epoch 7 and onwards, should
+        // be the new authorized voter
+        for i in 7..10 {
+            assert_eq!(
+                vote_state.get_and_update_authorized_voter(i).unwrap(),
+                new_authorized_voter
+            );
+        }
+        assert_eq!(vote_state.authorized_voters.len(), 1);
+    }
+
+    #[test]
+    fn test_set_new_authorized_voter() {
+        let original_voter = Pubkey::new_unique();
+        let epoch_offset = 15;
+        let mut vote_state = VoteStateV3::new(
+            &VoteInit {
+                node_pubkey: original_voter,
+                authorized_voter: original_voter,
+                authorized_withdrawer: original_voter,
+                commission: 0,
+            },
+            &Clock::default(),
+        );
+
+        assert!(vote_state.prior_voters.last().is_none());
+
+        let new_voter = Pubkey::new_unique();
+        // Set a new authorized voter
+        vote_state
+            .set_new_authorized_voter(&new_voter, 0, epoch_offset, |_| Ok(()))
+            .unwrap();
+
+        assert_eq!(vote_state.prior_voters.idx, 0);
+        assert_eq!(
+            vote_state.prior_voters.last(),
+            Some(&(original_voter, 0, epoch_offset))
+        );
+
+        // Trying to set authorized voter for same epoch again should fail
+        assert_eq!(
+            vote_state.set_new_authorized_voter(&new_voter, 0, epoch_offset, |_| Ok(())),
+            Err(VoteError::TooSoonToReauthorize.into())
+        );
+
+        // Setting the same authorized voter again should succeed
+        vote_state
+            .set_new_authorized_voter(&new_voter, 2, 2 + epoch_offset, |_| Ok(()))
+            .unwrap();
+
+        // Set a third and fourth authorized voter
+        let new_voter2 = Pubkey::new_unique();
+        vote_state
+            .set_new_authorized_voter(&new_voter2, 3, 3 + epoch_offset, |_| Ok(()))
+            .unwrap();
+        assert_eq!(vote_state.prior_voters.idx, 1);
+        assert_eq!(
+            vote_state.prior_voters.last(),
+            Some(&(new_voter, epoch_offset, 3 + epoch_offset))
+        );
+
+        let new_voter3 = Pubkey::new_unique();
+        vote_state
+            .set_new_authorized_voter(&new_voter3, 6, 6 + epoch_offset, |_| Ok(()))
+            .unwrap();
+        assert_eq!(vote_state.prior_voters.idx, 2);
+        assert_eq!(
+            vote_state.prior_voters.last(),
+            Some(&(new_voter2, 3 + epoch_offset, 6 + epoch_offset))
+        );
+
+        // Check can set back to original voter
+        vote_state
+            .set_new_authorized_voter(&original_voter, 9, 9 + epoch_offset, |_| Ok(()))
+            .unwrap();
+
+        // Run with these voters for a while, check the ranges of authorized
+        // voters is correct
+        for i in 9..epoch_offset {
+            assert_eq!(
+                vote_state.get_and_update_authorized_voter(i).unwrap(),
+                original_voter
+            );
+        }
+        for i in epoch_offset..3 + epoch_offset {
+            assert_eq!(
+                vote_state.get_and_update_authorized_voter(i).unwrap(),
+                new_voter
+            );
+        }
+        for i in 3 + epoch_offset..6 + epoch_offset {
+            assert_eq!(
+                vote_state.get_and_update_authorized_voter(i).unwrap(),
+                new_voter2
+            );
+        }
+        for i in 6 + epoch_offset..9 + epoch_offset {
+            assert_eq!(
+                vote_state.get_and_update_authorized_voter(i).unwrap(),
+                new_voter3
+            );
+        }
+        for i in 9 + epoch_offset..=10 + epoch_offset {
+            assert_eq!(
+                vote_state.get_and_update_authorized_voter(i).unwrap(),
+                original_voter
+            );
+        }
+    }
+
+    #[test]
+    fn test_authorized_voter_is_locked_within_epoch() {
+        let original_voter = Pubkey::new_unique();
+        let mut vote_state = VoteStateV3::new(
+            &VoteInit {
+                node_pubkey: original_voter,
+                authorized_voter: original_voter,
+                authorized_withdrawer: original_voter,
+                commission: 0,
+            },
+            &Clock::default(),
+        );
+
+        // Test that it's not possible to set a new authorized
+        // voter within the same epoch, even if none has been
+        // explicitly set before
+        let new_voter = Pubkey::new_unique();
+        assert_eq!(
+            vote_state.set_new_authorized_voter(&new_voter, 1, 1, |_| Ok(())),
+            Err(VoteError::TooSoonToReauthorize.into())
+        );
+
+        assert_eq!(vote_state.get_authorized_voter(1), Some(original_voter));
+
+        // Set a new authorized voter for a future epoch
+        assert_eq!(
+            vote_state.set_new_authorized_voter(&new_voter, 1, 2, |_| Ok(())),
+            Ok(())
+        );
+
+        // Test that it's not possible to set a new authorized
+        // voter within the same epoch, even if none has been
+        // explicitly set before
+        assert_eq!(
+            vote_state.set_new_authorized_voter(&original_voter, 3, 3, |_| Ok(())),
+            Err(VoteError::TooSoonToReauthorize.into())
+        );
+
+        assert_eq!(vote_state.get_authorized_voter(3), Some(new_voter));
+    }
+
+    #[test]
+    fn test_vote_state_size_of() {
+        let vote_state = VoteStateV3::get_max_sized_vote_state();
+        let vote_state = VoteStateVersions::new_v3(vote_state);
+        let size = serialized_size(&vote_state).unwrap();
+        assert_eq!(VoteStateV3::size_of() as u64, size);
+    }
+
+    #[test]
+    fn test_vote_state_max_size() {
+        let mut max_sized_data = vec![0; VoteStateV3::size_of()];
+        let vote_state = VoteStateV3::get_max_sized_vote_state();
+        let (start_leader_schedule_epoch, _) = vote_state.authorized_voters.last().unwrap();
+        let start_current_epoch =
+            start_leader_schedule_epoch - MAX_LEADER_SCHEDULE_EPOCH_OFFSET + 1;
+
+        let mut vote_state = Some(vote_state);
+        for i in start_current_epoch..start_current_epoch + 2 * MAX_LEADER_SCHEDULE_EPOCH_OFFSET {
+            vote_state.as_mut().map(|vote_state| {
+                vote_state.set_new_authorized_voter(
+                    &Pubkey::new_unique(),
+                    i,
+                    i + MAX_LEADER_SCHEDULE_EPOCH_OFFSET,
+                    |_| Ok(()),
+                )
+            });
+
+            let versioned = VoteStateVersions::new_v3(vote_state.take().unwrap());
+            VoteStateV3::serialize(&versioned, &mut max_sized_data).unwrap();
+            vote_state = Some(versioned.convert_to_v3());
+        }
+    }
+
+    #[test]
+    fn test_default_vote_state_is_uninitialized() {
+        // The default `VoteStateV3` is stored to de-initialize a zero-balance vote account,
+        // so must remain such that `VoteStateVersions::is_uninitialized()` returns true
+        // when called on a `VoteStateVersions` that stores it
+        assert!(VoteStateVersions::new_v3(VoteStateV3::default()).is_uninitialized());
+    }
+
+    #[test]
+    fn test_is_correct_size_and_initialized() {
+        // Check all zeroes
+        let mut vote_account_data = vec![0; VoteStateVersions::vote_state_size_of(true)];
+        assert!(!VoteStateVersions::is_correct_size_and_initialized(
+            &vote_account_data
+        ));
+
+        // Check default VoteStateV3
+        let default_account_state = VoteStateVersions::new_v3(VoteStateV3::default());
+        VoteStateV3::serialize(&default_account_state, &mut vote_account_data).unwrap();
+        assert!(!VoteStateVersions::is_correct_size_and_initialized(
+            &vote_account_data
+        ));
+
+        // Check non-zero data shorter than offset index used
+        let short_data = vec![1; DEFAULT_PRIOR_VOTERS_OFFSET];
+        assert!(!VoteStateVersions::is_correct_size_and_initialized(
+            &short_data
+        ));
+
+        // Check non-zero large account
+        let mut large_vote_data = vec![1; 2 * VoteStateVersions::vote_state_size_of(true)];
+        let default_account_state = VoteStateVersions::new_v3(VoteStateV3::default());
+        VoteStateV3::serialize(&default_account_state, &mut large_vote_data).unwrap();
+        assert!(!VoteStateVersions::is_correct_size_and_initialized(
+            &vote_account_data
+        ));
+
+        // Check populated VoteStateV3
+        let vote_state = VoteStateV3::new(
+            &VoteInit {
+                node_pubkey: Pubkey::new_unique(),
+                authorized_voter: Pubkey::new_unique(),
+                authorized_withdrawer: Pubkey::new_unique(),
+                commission: 0,
+            },
+            &Clock::default(),
+        );
+        let account_state = VoteStateVersions::new_v3(vote_state.clone());
+        VoteStateV3::serialize(&account_state, &mut vote_account_data).unwrap();
+        assert!(VoteStateVersions::is_correct_size_and_initialized(
+            &vote_account_data
+        ));
+
+        // Check old VoteStateV3 that hasn't been upgraded to newest version yet
+        let old_vote_state = VoteState1_14_11::from(vote_state);
+        let account_state = VoteStateVersions::V1_14_11(Box::new(old_vote_state));
+        let mut vote_account_data = vec![0; VoteStateVersions::vote_state_size_of(false)];
+        VoteStateV3::serialize(&account_state, &mut vote_account_data).unwrap();
+        assert!(VoteStateVersions::is_correct_size_and_initialized(
+            &vote_account_data
+        ));
+    }
+
+    #[test]
+    fn test_minimum_balance() {
+        let rent = solana_rent::Rent::default();
+        let minimum_balance = rent.minimum_balance(VoteStateV3::size_of());
+        // golden, may need updating when vote_state grows
+        assert!(minimum_balance as f64 / 10f64.powf(9.0) < 0.04)
+    }
+
+    #[test]
+    fn test_serde_compact_vote_state_update() {
+        let mut rng = rand::thread_rng();
+        for _ in 0..5000 {
+            run_serde_compact_vote_state_update(&mut rng);
+        }
+    }
+
+    fn run_serde_compact_vote_state_update<R: Rng>(rng: &mut R) {
+        let lockouts: VecDeque<_> = std::iter::repeat_with(|| {
+            let slot = 149_303_885_u64.saturating_add(rng.gen_range(0..10_000));
+            let confirmation_count = rng.gen_range(0..33);
+            Lockout::new_with_confirmation_count(slot, confirmation_count)
+        })
+        .take(32)
+        .sorted_by_key(|lockout| lockout.slot())
+        .collect();
+        let root = rng.gen_ratio(1, 2).then(|| {
+            lockouts[0]
+                .slot()
+                .checked_sub(rng.gen_range(0..1_000))
+                .expect("All slots should be greater than 1_000")
+        });
+        let timestamp = rng.gen_ratio(1, 2).then(|| rng.gen());
+        let hash = Hash::from(rng.gen::<[u8; 32]>());
+        let vote_state_update = VoteStateUpdate {
+            lockouts,
+            root,
+            hash,
+            timestamp,
+        };
+        #[derive(Debug, Eq, PartialEq, Deserialize, Serialize)]
+        enum VoteInstruction {
+            #[serde(with = "serde_compact_vote_state_update")]
+            UpdateVoteState(VoteStateUpdate),
+            UpdateVoteStateSwitch(
+                #[serde(with = "serde_compact_vote_state_update")] VoteStateUpdate,
+                Hash,
+            ),
+        }
+        let vote = VoteInstruction::UpdateVoteState(vote_state_update.clone());
+        let bytes = bincode::serialize(&vote).unwrap();
+        assert_eq!(vote, bincode::deserialize(&bytes).unwrap());
+        let hash = Hash::from(rng.gen::<[u8; 32]>());
+        let vote = VoteInstruction::UpdateVoteStateSwitch(vote_state_update, hash);
+        let bytes = bincode::serialize(&vote).unwrap();
+        assert_eq!(vote, bincode::deserialize(&bytes).unwrap());
+    }
+
+    #[test]
+    fn test_circbuf_oob() {
+        // Craft an invalid CircBuf with out-of-bounds index
+        let data: &[u8] = &[0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x00];
+        let circ_buf: CircBuf<()> = bincode::deserialize(data).unwrap();
+        assert_eq!(circ_buf.last(), None);
+    }
+}
diff --git a/vote-interface/src/state/vote_instruction_data.rs b/vote-interface/src/state/vote_instruction_data.rs
new file mode 100644
index 0000000000..136f2d71cf
--- /dev/null
+++ b/vote-interface/src/state/vote_instruction_data.rs
@@ -0,0 +1,226 @@
+#[cfg(feature = "serde")]
+use serde_derive::{Deserialize, Serialize};
+#[cfg(feature = "frozen-abi")]
+use solana_frozen_abi_macro::{frozen_abi, AbiExample};
+use {
+    crate::state::{Lockout, MAX_LOCKOUT_HISTORY},
+    solana_clock::{Slot, UnixTimestamp},
+    solana_hash::Hash,
+    solana_pubkey::Pubkey,
+    std::{collections::VecDeque, fmt::Debug},
+};
+
+#[cfg_attr(
+    feature = "frozen-abi",
+    frozen_abi(digest = "GvUzgtcxhKVVxPAjSntXGPqjLZK5ovgZzCiUP1tDpB9q"),
+    derive(AbiExample)
+)]
+#[cfg_attr(feature = "serde", derive(Deserialize, Serialize))]
+#[derive(Default, Debug, PartialEq, Eq, Clone)]
+pub struct Vote {
+    /// A stack of votes starting with the oldest vote
+    pub slots: Vec<Slot>,
+    /// signature of the bank's state at the last slot
+    pub hash: Hash,
+    /// processing timestamp of last slot
+    pub timestamp: Option<UnixTimestamp>,
+}
+
+impl Vote {
+    pub fn new(slots: Vec<Slot>, hash: Hash) -> Self {
+        Self {
+            slots,
+            hash,
+            timestamp: None,
+        }
+    }
+
+    pub fn last_voted_slot(&self) -> Option<Slot> {
+        self.slots.last().copied()
+    }
+}
+
+#[cfg_attr(
+    feature = "frozen-abi",
+    frozen_abi(digest = "CxyuwbaEdzP7jDCZyxjgQvLGXadBUZF3LoUvbSpQ6tYN"),
+    derive(AbiExample)
+)]
+#[cfg_attr(feature = "serde", derive(Deserialize, Serialize))]
+#[derive(Default, Debug, PartialEq, Eq, Clone)]
+pub struct VoteStateUpdate {
+    /// The proposed tower
+    pub lockouts: VecDeque<Lockout>,
+    /// The proposed root
+    pub root: Option<Slot>,
+    /// signature of the bank's state at the last slot
+    pub hash: Hash,
+    /// processing timestamp of last slot
+    pub timestamp: Option<UnixTimestamp>,
+}
+
+impl From<Vec<(Slot, u32)>> for VoteStateUpdate {
+    fn from(recent_slots: Vec<(Slot, u32)>) -> Self {
+        let lockouts: VecDeque<Lockout> = recent_slots
+            .into_iter()
+            .map(|(slot, confirmation_count)| {
+                Lockout::new_with_confirmation_count(slot, confirmation_count)
+            })
+            .collect();
+        Self {
+            lockouts,
+            root: None,
+            hash: Hash::default(),
+            timestamp: None,
+        }
+    }
+}
+
+impl VoteStateUpdate {
+    pub fn new(lockouts: VecDeque<Lockout>, root: Option<Slot>, hash: Hash) -> Self {
+        Self {
+            lockouts,
+            root,
+            hash,
+            timestamp: None,
+        }
+    }
+
+    pub fn slots(&self) -> Vec<Slot> {
+        self.lockouts.iter().map(|lockout| lockout.slot()).collect()
+    }
+
+    pub fn last_voted_slot(&self) -> Option<Slot> {
+        self.lockouts.back().map(|l| l.slot())
+    }
+}
+
+#[cfg_attr(
+    feature = "frozen-abi",
+    frozen_abi(digest = "6UDiQMH4wbNwkMHosPMtekMYu2Qa6CHPZ2ymK4mc6FGu"),
+    derive(AbiExample)
+)]
+#[cfg_attr(feature = "serde", derive(Deserialize, Serialize))]
+#[derive(Default, Debug, PartialEq, Eq, Clone)]
+pub struct TowerSync {
+    /// The proposed tower
+    pub lockouts: VecDeque<Lockout>,
+    /// The proposed root
+    pub root: Option<Slot>,
+    /// signature of the bank's state at the last slot
+    pub hash: Hash,
+    /// processing timestamp of last slot
+    pub timestamp: Option<UnixTimestamp>,
+    /// the unique identifier for the chain up to and
+    /// including this block. Does not require replaying
+    /// in order to compute.
+    pub block_id: Hash,
+}
+
+impl From<Vec<(Slot, u32)>> for TowerSync {
+    fn from(recent_slots: Vec<(Slot, u32)>) -> Self {
+        let lockouts: VecDeque<Lockout> = recent_slots
+            .into_iter()
+            .map(|(slot, confirmation_count)| {
+                Lockout::new_with_confirmation_count(slot, confirmation_count)
+            })
+            .collect();
+        Self {
+            lockouts,
+            root: None,
+            hash: Hash::default(),
+            timestamp: None,
+            block_id: Hash::default(),
+        }
+    }
+}
+
+impl TowerSync {
+    pub fn new(
+        lockouts: VecDeque<Lockout>,
+        root: Option<Slot>,
+        hash: Hash,
+        block_id: Hash,
+    ) -> Self {
+        Self {
+            lockouts,
+            root,
+            hash,
+            timestamp: None,
+            block_id,
+        }
+    }
+
+    /// Creates a tower with consecutive votes for `slot - MAX_LOCKOUT_HISTORY + 1` to `slot` inclusive.
+    /// If `slot >= MAX_LOCKOUT_HISTORY`, sets the root to `(slot - MAX_LOCKOUT_HISTORY)`
+    /// Sets the hash to `hash` and leaves `block_id` unset.
+    pub fn new_from_slot(slot: Slot, hash: Hash) -> Self {
+        let lowest_slot = slot
+            .saturating_add(1)
+            .saturating_sub(MAX_LOCKOUT_HISTORY as u64);
+        let slots: Vec<_> = (lowest_slot..slot.saturating_add(1)).collect();
+        Self::new_from_slots(
+            slots,
+            hash,
+            (lowest_slot > 0).then(|| lowest_slot.saturating_sub(1)),
+        )
+    }
+
+    /// Creates a tower with consecutive confirmation for `slots`
+    pub fn new_from_slots(slots: Vec<Slot>, hash: Hash, root: Option<Slot>) -> Self {
+        let lockouts: VecDeque<Lockout> = slots
+            .into_iter()
+            .rev()
+            .enumerate()
+            .map(|(cc, s)| Lockout::new_with_confirmation_count(s, cc.saturating_add(1) as u32))
+            .rev()
+            .collect();
+        Self {
+            lockouts,
+            hash,
+            root,
+            timestamp: None,
+            block_id: Hash::default(),
+        }
+    }
+
+    pub fn slots(&self) -> Vec<Slot> {
+        self.lockouts.iter().map(|lockout| lockout.slot()).collect()
+    }
+
+    pub fn last_voted_slot(&self) -> Option<Slot> {
+        self.lockouts.back().map(|l| l.slot())
+    }
+}
+
+#[cfg_attr(feature = "serde", derive(Deserialize, Serialize))]
+#[derive(Default, Debug, PartialEq, Eq, Clone, Copy)]
+pub struct VoteInit {
+    pub node_pubkey: Pubkey,
+    pub authorized_voter: Pubkey,
+    pub authorized_withdrawer: Pubkey,
+    pub commission: u8,
+}
+
+#[cfg_attr(feature = "serde", derive(Deserialize, Serialize))]
+#[derive(Debug, PartialEq, Eq, Clone, Copy)]
+pub enum VoteAuthorize {
+    Voter,
+    Withdrawer,
+}
+
+#[cfg_attr(feature = "serde", derive(Deserialize, Serialize))]
+#[derive(Debug, PartialEq, Eq, Clone)]
+pub struct VoteAuthorizeWithSeedArgs {
+    pub authorization_type: VoteAuthorize,
+    pub current_authority_derived_key_owner: Pubkey,
+    pub current_authority_derived_key_seed: String,
+    pub new_authority: Pubkey,
+}
+
+#[cfg_attr(feature = "serde", derive(Deserialize, Serialize))]
+#[derive(Debug, PartialEq, Eq, Clone)]
+pub struct VoteAuthorizeCheckedWithSeedArgs {
+    pub authorization_type: VoteAuthorize,
+    pub current_authority_derived_key_owner: Pubkey,
+    pub current_authority_derived_key_seed: String,
+}
diff --git a/vote-interface/src/state/vote_state_0_23_5.rs b/vote-interface/src/state/vote_state_0_23_5.rs
new file mode 100644
index 0000000000..fc781bf83e
--- /dev/null
+++ b/vote-interface/src/state/vote_state_0_23_5.rs
@@ -0,0 +1,107 @@
+#![allow(clippy::arithmetic_side_effects)]
+use super::*;
+#[cfg(test)]
+use arbitrary::{Arbitrary, Unstructured};
+
+const MAX_ITEMS: usize = 32;
+
+#[cfg_attr(feature = "serde", derive(Deserialize, Serialize))]
+#[derive(Debug, Default, PartialEq, Eq, Clone)]
+#[cfg_attr(test, derive(Arbitrary))]
+pub struct VoteState0_23_5 {
+    /// the node that votes in this account
+    pub node_pubkey: Pubkey,
+
+    /// the signer for vote transactions
+    pub authorized_voter: Pubkey,
+    /// when the authorized voter was set/initialized
+    pub authorized_voter_epoch: Epoch,
+
+    /// history of prior authorized voters and the epoch ranges for which
+    ///  they were set
+    pub prior_voters: CircBuf<(Pubkey, Epoch, Epoch, Slot)>,
+
+    /// the signer for withdrawals
+    pub authorized_withdrawer: Pubkey,
+    /// percentage (0-100) that represents what part of a rewards
+    ///  payout should be given to this VoteAccount
+    pub commission: u8,
+
+    pub votes: VecDeque<Lockout>,
+    pub root_slot: Option<u64>,
+
+    /// history of how many credits earned by the end of each epoch
+    ///  each tuple is (Epoch, credits, prev_credits)
+    pub epoch_credits: Vec<(Epoch, u64, u64)>,
+
+    /// most recent timestamp submitted with a vote
+    pub last_timestamp: BlockTimestamp,
+}
+
+#[cfg_attr(feature = "serde", derive(Deserialize, Serialize))]
+#[derive(Debug, PartialEq, Eq, Clone)]
+#[cfg_attr(test, derive(Arbitrary))]
+pub struct CircBuf<I> {
+    pub buf: [I; MAX_ITEMS],
+    /// next pointer
+    pub idx: usize,
+}
+
+impl<I: Default + Copy> Default for CircBuf<I> {
+    fn default() -> Self {
+        Self {
+            buf: [I::default(); MAX_ITEMS],
+            idx: MAX_ITEMS - 1,
+        }
+    }
+}
+
+impl<I> CircBuf<I> {
+    pub fn append(&mut self, item: I) {
+        // remember prior delegate and when we switched, to support later slashing
+        self.idx += 1;
+        self.idx %= MAX_ITEMS;
+
+        self.buf[self.idx] = item;
+    }
+}
+
+#[cfg(test)]
+mod tests {
+    use {super::*, core::mem::MaybeUninit};
+
+    #[test]
+    fn test_vote_deserialize_0_23_5() {
+        // base case
+        let target_vote_state = VoteState0_23_5::default();
+        let target_vote_state_versions = VoteStateVersions::V0_23_5(Box::new(target_vote_state));
+        let vote_state_buf = bincode::serialize(&target_vote_state_versions).unwrap();
+
+        let mut test_vote_state = MaybeUninit::uninit();
+        VoteStateV3::deserialize_into_uninit(&vote_state_buf, &mut test_vote_state).unwrap();
+        let test_vote_state = unsafe { test_vote_state.assume_init() };
+
+        assert_eq!(target_vote_state_versions.convert_to_v3(), test_vote_state);
+
+        // variant
+        // provide 4x the minimum struct size in bytes to ensure we typically touch every field
+        let struct_bytes_x4 = std::mem::size_of::<VoteState0_23_5>() * 4;
+        for _ in 0..100 {
+            let raw_data: Vec<u8> = (0..struct_bytes_x4).map(|_| rand::random::<u8>()).collect();
+            let mut unstructured = Unstructured::new(&raw_data);
+
+            let arbitrary_vote_state = VoteState0_23_5::arbitrary(&mut unstructured).unwrap();
+            let target_vote_state_versions =
+                VoteStateVersions::V0_23_5(Box::new(arbitrary_vote_state));
+
+            let vote_state_buf = bincode::serialize(&target_vote_state_versions).unwrap();
+            let target_vote_state = target_vote_state_versions.convert_to_v3();
+
+            let mut test_vote_state = MaybeUninit::uninit();
+            VoteStateV3::deserialize_into_uninit(&vote_state_buf, &mut test_vote_state).unwrap();
+            let test_vote_state = unsafe { test_vote_state.assume_init() };
+
+            assert_eq!(target_vote_state, test_vote_state);
+        }
+    }
+}
diff --git a/vote-interface/src/state/vote_state_1_14_11.rs b/vote-interface/src/state/vote_state_1_14_11.rs
new file mode 100644
index 0000000000..27eb7f6438
--- /dev/null
+++ b/vote-interface/src/state/vote_state_1_14_11.rs
@@ -0,0 +1,125 @@
+use super::*;
+#[cfg(feature = "dev-context-only-utils")]
+use arbitrary::Arbitrary;
+
+// Offset used for VoteState version 1_14_11
+const DEFAULT_PRIOR_VOTERS_OFFSET: usize = 82;
+
+#[cfg_attr(
+    feature = "frozen-abi",
+    solana_frozen_abi_macro::frozen_abi(digest = "2rjXSWaNeAdoUNJDC5otC7NPR1qXHvLMuAs5faE4DPEt"),
+    derive(solana_frozen_abi_macro::AbiExample)
+)]
+#[cfg_attr(feature = "serde", derive(Deserialize, Serialize))]
+#[derive(Debug, Default, PartialEq, Eq, Clone)]
+#[cfg_attr(feature = "dev-context-only-utils", derive(Arbitrary))]
+pub struct VoteState1_14_11 {
+    /// the node that votes in this account
+    pub node_pubkey: Pubkey,
+
+    /// the signer for withdrawals
+    pub authorized_withdrawer: Pubkey,
+    /// percentage (0-100) that represents what part of a rewards
+    ///  payout should be given to this VoteAccount
+    pub commission: u8,
+
+    pub votes: VecDeque<Lockout>,
+
+    // This usually the last Lockout which was popped from self.votes.
+    // However, it can be arbitrary slot, when being used inside Tower
+    pub root_slot: Option<Slot>,
+
+    /// the signer for vote transactions
+    pub authorized_voters: AuthorizedVoters,
+
+    /// history of prior authorized voters and the epochs for which
+    /// they were set, the bottom end of the range is inclusive,
+    /// the top of the range is exclusive
+    pub prior_voters: CircBuf<(Pubkey, Epoch, Epoch)>,
+
+    /// history of how many credits earned by the end of each epoch
+    ///  each tuple is (Epoch, credits, prev_credits)
+    pub epoch_credits: Vec<(Epoch, u64, u64)>,
+
+    /// most recent timestamp submitted with a vote
+    pub last_timestamp: BlockTimestamp,
+}
+
+impl VoteState1_14_11 {
+    pub fn get_rent_exempt_reserve(rent: &Rent) -> u64 {
+        rent.minimum_balance(Self::size_of())
+    }
+
+    /// Upper limit on the size of the Vote State
+    /// when votes.len() is MAX_LOCKOUT_HISTORY.
+    pub fn size_of() -> usize {
+        3731 // see test_vote_state_size_of
+    }
+
+    pub fn is_correct_size_and_initialized(data: &[u8]) -> bool {
+        const VERSION_OFFSET: usize = 4;
+        const DEFAULT_PRIOR_VOTERS_END: usize = VERSION_OFFSET + DEFAULT_PRIOR_VOTERS_OFFSET;
+        data.len() == VoteState1_14_11::size_of()
+            && data[VERSION_OFFSET..DEFAULT_PRIOR_VOTERS_END] != [0; DEFAULT_PRIOR_VOTERS_OFFSET]
+    }
+}
+
+impl From<VoteStateV3> for VoteState1_14_11 {
+    fn from(vote_state: VoteStateV3) -> Self {
+        Self {
+            node_pubkey: vote_state.node_pubkey,
+            authorized_withdrawer: vote_state.authorized_withdrawer,
+            commission: vote_state.commission,
+            votes: vote_state
+                .votes
+                .into_iter()
+                .map(|landed_vote| landed_vote.into())
+                .collect(),
+            root_slot: vote_state.root_slot,
+            authorized_voters: vote_state.authorized_voters,
+            prior_voters: vote_state.prior_voters,
+            epoch_credits: vote_state.epoch_credits,
+            last_timestamp: vote_state.last_timestamp,
+        }
+    }
+}
+
+#[cfg(test)]
+mod tests {
+    use {super::*, core::mem::MaybeUninit};
+
+    #[test]
+    fn test_vote_deserialize_1_14_11() {
+        // base case
+        let target_vote_state = VoteState1_14_11::default();
+        let target_vote_state_versions = VoteStateVersions::V1_14_11(Box::new(target_vote_state));
+        let vote_state_buf = bincode::serialize(&target_vote_state_versions).unwrap();
+
+        let mut test_vote_state = MaybeUninit::uninit();
+        VoteStateV3::deserialize_into_uninit(&vote_state_buf, &mut test_vote_state).unwrap();
+        let test_vote_state = unsafe { test_vote_state.assume_init() };
+
+        assert_eq!(target_vote_state_versions.convert_to_v3(), test_vote_state);
+
+        // variant
+        // provide 4x the minimum struct size in bytes to ensure we typically touch every field
+        let struct_bytes_x4 = std::mem::size_of::<VoteState1_14_11>() * 4;
+        for _ in 0..1000 {
+            let raw_data: Vec<u8> = (0..struct_bytes_x4).map(|_| rand::random::<u8>()).collect();
+            let mut unstructured = Unstructured::new(&raw_data);
+
+            let arbitrary_vote_state = VoteState1_14_11::arbitrary(&mut unstructured).unwrap();
+            let target_vote_state_versions =
+                VoteStateVersions::V1_14_11(Box::new(arbitrary_vote_state));
+
+            let vote_state_buf = bincode::serialize(&target_vote_state_versions).unwrap();
+            let target_vote_state = target_vote_state_versions.convert_to_v3();
+
+            let mut test_vote_state = MaybeUninit::uninit();
+            VoteStateV3::deserialize_into_uninit(&vote_state_buf, &mut test_vote_state).unwrap();
+            let test_vote_state = unsafe { test_vote_state.assume_init() };
+
+            assert_eq!(target_vote_state, test_vote_state);
+        }
+    }
+}
diff --git a/vote-interface/src/state/vote_state_deserialize.rs b/vote-interface/src/state/vote_state_deserialize.rs
new file mode 100644
index 0000000000..c90afa40c4
--- /dev/null
+++ b/vote-interface/src/state/vote_state_deserialize.rs
@@ -0,0 +1,205 @@
+use {
+    crate::{
+        authorized_voters::AuthorizedVoters,
+        state::{
+            BlockTimestamp, LandedVote, Lockout, VoteStateV3, MAX_EPOCH_CREDITS_HISTORY, MAX_ITEMS,
+            MAX_LOCKOUT_HISTORY,
+        },
+    },
+    solana_clock::Epoch,
+    solana_instruction_error::InstructionError,
+    solana_pubkey::Pubkey,
+    solana_serialize_utils::cursor::{
+        read_bool, read_i64, read_option_u64, read_pubkey, read_pubkey_into, read_u32, read_u64,
+        read_u8,
+    },
+    std::{collections::VecDeque, io::Cursor, ptr::addr_of_mut},
+};
+
+// This is to reset vote_state to T::default() if deserialize fails or panics.
+struct DropGuard<T: Default> {
+    vote_state: *mut T,
+}
+
+impl<T: Default> Drop for DropGuard<T> {
+    fn drop(&mut self) {
+        // Safety:
+        //
+        // Deserialize failed or panicked so at this point vote_state is uninitialized. We
+        // must write a new _valid_ value into it or after returning (or unwinding) from
+        // this function the caller is left with an uninitialized `&mut T`, which is UB
+        // (references must always be valid).
+        //
+        // This is always safe and doesn't leak memory because deserialize_into_ptr() writes
+        // into the fields that heap alloc only when it returns Ok().
+        unsafe {
+            self.vote_state.write(T::default());
+        }
+    }
+}
+
+pub(crate) fn deserialize_into<T: Default>(
+    input: &[u8],
+    vote_state: &mut T,
+    deserialize_fn: impl FnOnce(&[u8], *mut T) -> Result<(), InstructionError>,
+) -> Result<(), InstructionError> {
+    // Rebind vote_state to *mut T so that the &mut binding isn't accessible
+    // anymore, preventing accidental use after this point.
+    //
+    // NOTE: switch to ptr::from_mut() once platform-tools moves to rustc >= 1.76
+    let vote_state = vote_state as *mut T;
+
+    // Safety: vote_state is valid to_drop (see drop_in_place() docs). After
+    // dropping, the pointer is treated as uninitialized and only accessed
+    // through ptr::write, which is safe as per drop_in_place docs.
+    unsafe {
+        std::ptr::drop_in_place(vote_state);
+    }
+
+    // This is to reset vote_state to T::default() if deserialize fails or panics.
+    let guard = DropGuard { vote_state };
+
+    let res = deserialize_fn(input, vote_state);
+    if res.is_ok() {
+        std::mem::forget(guard);
+    }
+
+    res
+}
+
+pub(super) fn deserialize_vote_state_into(
+    cursor: &mut Cursor<&[u8]>,
+    vote_state: *mut VoteStateV3,
+    has_latency: bool,
+) -> Result<(), InstructionError> {
+    // General safety note: we must use add_or_mut! to access the `vote_state` fields as the value
+    // is assumed to be _uninitialized_, so creating references to the state or any of its inner
+    // fields is UB.
+
+    read_pubkey_into(
+        cursor,
+        // Safety: if vote_state is non-null, node_pubkey is guaranteed to be valid too
+        unsafe { addr_of_mut!((*vote_state).node_pubkey) },
+    )?;
+    read_pubkey_into(
+        cursor,
+        // Safety: if vote_state is non-null, authorized_withdrawer is guaranteed to be valid too
+        unsafe { addr_of_mut!((*vote_state).authorized_withdrawer) },
+    )?;
+    let commission = read_u8(cursor)?;
+    let votes = read_votes(cursor, has_latency)?;
+    let root_slot = read_option_u64(cursor)?;
+    let authorized_voters = read_authorized_voters(cursor)?;
+    read_prior_voters_into(cursor, vote_state)?;
+    let epoch_credits = read_epoch_credits(cursor)?;
+    read_last_timestamp_into(cursor, vote_state)?;
+
+    // Safety: if vote_state is non-null, all the fields are guaranteed to be
+    // valid pointers.
+    //
+    // Heap allocated collections - votes, authorized_voters and epoch_credits -
+    // are guaranteed not to leak after this point as the VoteStateV3 is fully
+    // initialized and will be regularly dropped.
+    unsafe {
+        addr_of_mut!((*vote_state).commission).write(commission);
+        addr_of_mut!((*vote_state).votes).write(votes);
+        addr_of_mut!((*vote_state).root_slot).write(root_slot);
+        addr_of_mut!((*vote_state).authorized_voters).write(authorized_voters);
+        addr_of_mut!((*vote_state).epoch_credits).write(epoch_credits);
+    }
+
+    Ok(())
+}
+
+fn read_votes<T: AsRef<[u8]>>(
+    cursor: &mut Cursor<T>,
+    has_latency: bool,
+) -> Result<VecDeque<LandedVote>, InstructionError> {
+    let vote_count = read_u64(cursor)? as usize;
+    let mut votes = VecDeque::with_capacity(vote_count.min(MAX_LOCKOUT_HISTORY));
+
+    for _ in 0..vote_count {
+        let latency = if has_latency { read_u8(cursor)? } else { 0 };
+
+        let slot = read_u64(cursor)?;
+        let confirmation_count = read_u32(cursor)?;
+        let lockout = Lockout::new_with_confirmation_count(slot, confirmation_count);
+
+        votes.push_back(LandedVote { latency, lockout });
+    }
+
+    Ok(votes)
+}
+
+fn read_authorized_voters<T: AsRef<[u8]>>(
+    cursor: &mut Cursor<T>,
+) -> Result<AuthorizedVoters, InstructionError> {
+    let authorized_voter_count = read_u64(cursor)?;
+    let mut authorized_voters = AuthorizedVoters::default();
+
+    for _ in 0..authorized_voter_count {
+        let epoch = read_u64(cursor)?;
+        let authorized_voter = read_pubkey(cursor)?;
+        authorized_voters.insert(epoch, authorized_voter);
+    }
+
+    Ok(authorized_voters)
+}
+
+fn read_prior_voters_into<T: AsRef<[u8]>>(
+    cursor: &mut Cursor<T>,
+    vote_state: *mut VoteStateV3,
+) -> Result<(), InstructionError> {
+    // Safety: if vote_state is non-null, prior_voters is guaranteed to be valid too
+    unsafe {
+        let prior_voters = addr_of_mut!((*vote_state).prior_voters);
+        let prior_voters_buf = addr_of_mut!((*prior_voters).buf) as *mut (Pubkey, Epoch, Epoch);
+
+        for i in 0..MAX_ITEMS {
+            let prior_voter = read_pubkey(cursor)?;
+            let from_epoch = read_u64(cursor)?;
+            let until_epoch = read_u64(cursor)?;
+
+            prior_voters_buf
+                .add(i)
+                .write((prior_voter, from_epoch, until_epoch));
+        }
+
+        (*vote_state).prior_voters.idx = read_u64(cursor)? as usize;
+        (*vote_state).prior_voters.is_empty = read_bool(cursor)?;
+    }
+    Ok(())
+}
+
+fn read_epoch_credits<T: AsRef<[u8]>>(
+    cursor: &mut Cursor<T>,
+) -> Result<Vec<(Epoch, u64, u64)>, InstructionError> {
+    let epoch_credit_count = read_u64(cursor)? as usize;
+    let mut epoch_credits = Vec::with_capacity(epoch_credit_count.min(MAX_EPOCH_CREDITS_HISTORY));
+
+    for _ in 0..epoch_credit_count {
+        let epoch = read_u64(cursor)?;
+        let credits = read_u64(cursor)?;
+        let prev_credits = read_u64(cursor)?;
+        epoch_credits.push((epoch, credits, prev_credits));
+    }
+
+    Ok(epoch_credits)
+}
+
+fn read_last_timestamp_into<T: AsRef<[u8]>>(
+    cursor: &mut Cursor<T>,
+    vote_state: *mut VoteStateV3,
+) -> Result<(), InstructionError> {
+    let slot = read_u64(cursor)?;
+    let timestamp = read_i64(cursor)?;
+
+    let last_timestamp = BlockTimestamp { slot, timestamp };
+
+    // Safety: if vote_state is non-null, last_timestamp is guaranteed to be valid too
+    unsafe {
+        addr_of_mut!((*vote_state).last_timestamp).write(last_timestamp);
+    }
+
+    Ok(())
+}
diff --git a/vote-interface/src/state/vote_state_v3.rs b/vote-interface/src/state/vote_state_v3.rs
new file mode 100644
index 0000000000..c22ca08e51
--- /dev/null
+++ b/vote-interface/src/state/vote_state_v3.rs
@@ -0,0 +1,528 @@
+#[cfg(feature = "bincode")]
+use super::VoteStateVersions;
+#[cfg(feature = "dev-context-only-utils")]
+use arbitrary::Arbitrary;
+#[cfg(feature = "serde")]
+use serde_derive::{Deserialize, Serialize};
+#[cfg(feature = "frozen-abi")]
+use solana_frozen_abi_macro::{frozen_abi, AbiExample};
+use {
+    super::{
+        BlockTimestamp, CircBuf, LandedVote, Lockout, VoteInit, MAX_EPOCH_CREDITS_HISTORY,
+        MAX_LOCKOUT_HISTORY, VOTE_CREDITS_GRACE_SLOTS, VOTE_CREDITS_MAXIMUM_PER_SLOT,
+    },
+    crate::{
+        authorized_voters::AuthorizedVoters, error::VoteError, state::DEFAULT_PRIOR_VOTERS_OFFSET,
+    },
+    solana_clock::{Clock, Epoch, Slot, UnixTimestamp},
+    solana_instruction_error::InstructionError,
+    solana_pubkey::Pubkey,
+    solana_rent::Rent,
+    std::{collections::VecDeque, fmt::Debug},
+};
+
+#[cfg_attr(
+    feature = "frozen-abi",
+    frozen_abi(digest = "pZqasQc6duzMYzpzU7eriHH9cMXmubuUP4NmCrkWZjt"),
+    derive(AbiExample)
+)]
+#[cfg_attr(feature = "serde", derive(Deserialize, Serialize))]
+#[derive(Debug, Default, PartialEq, Eq, Clone)]
+#[cfg_attr(feature = "dev-context-only-utils", derive(Arbitrary))]
+pub struct VoteStateV3 {
+    /// the node that votes in this account
+    pub node_pubkey: Pubkey,
+
+    /// the signer for withdrawals
+    pub authorized_withdrawer: Pubkey,
+    /// percentage (0-100) that represents what part of a rewards
+    ///  payout should be given to this VoteAccount
+    pub commission: u8,
+
+    pub votes: VecDeque<LandedVote>,
+
+    // This usually the last Lockout which was popped from self.votes.
+    // However, it can be arbitrary slot, when being used inside Tower
+    pub root_slot: Option<Slot>,
+
+    /// the signer for vote transactions
+    pub authorized_voters: AuthorizedVoters,
+
+    /// history of prior authorized voters and the epochs for which
+    /// they were set, the bottom end of the range is inclusive,
+    /// the top of the range is exclusive
+    pub prior_voters: CircBuf<(Pubkey, Epoch, Epoch)>,
+
+    /// history of how many credits earned by the end of each epoch
+    ///  each tuple is (Epoch, credits, prev_credits)
+    pub epoch_credits: Vec<(Epoch, u64, u64)>,
+
+    /// most recent timestamp submitted with a vote
+    pub last_timestamp: BlockTimestamp,
+}
+
+impl VoteStateV3 {
+    pub fn new(vote_init: &VoteInit, clock: &Clock) -> Self {
+        Self {
+            node_pubkey: vote_init.node_pubkey,
+            authorized_voters: AuthorizedVoters::new(clock.epoch, vote_init.authorized_voter),
+            authorized_withdrawer: vote_init.authorized_withdrawer,
+            commission: vote_init.commission,
+            ..VoteStateV3::default()
+        }
+    }
+
+    pub fn new_rand_for_tests(node_pubkey: Pubkey, root_slot: Slot) -> Self {
+        let votes = (1..32)
+            .map(|x| LandedVote {
+                latency: 0,
+                lockout: Lockout::new_with_confirmation_count(
+                    u64::from(x).saturating_add(root_slot),
+                    32_u32.saturating_sub(x),
+                ),
+            })
+            .collect();
+        Self {
+            node_pubkey,
+            root_slot: Some(root_slot),
+            votes,
+            ..VoteStateV3::default()
+        }
+    }
+
+    pub fn get_authorized_voter(&self, epoch: Epoch) -> Option<Pubkey> {
+        self.authorized_voters.get_authorized_voter(epoch)
+    }
+
+    pub fn authorized_voters(&self) -> &AuthorizedVoters {
+        &self.authorized_voters
+    }
+
+    pub fn prior_voters(&mut self) -> &CircBuf<(Pubkey, Epoch, Epoch)> {
+        &self.prior_voters
+    }
+
+    pub fn get_rent_exempt_reserve(rent: &Rent) -> u64 {
+        rent.minimum_balance(VoteStateV3::size_of())
+    }
+
+    /// Upper limit on the size of the Vote State
+    /// when votes.len() is MAX_LOCKOUT_HISTORY.
+    pub const fn size_of() -> usize {
+        3762 // see test_vote_state_size_of.
+    }
+
+    // NOTE we retain `bincode::deserialize` for `not(target_os = "solana")` pending testing on mainnet-beta
+    // once that testing is done, `VoteStateV3::deserialize_into` may be used for all targets
+    // conversion of V0_23_5 to v3 must be handled specially, however
+    // because it inserts a null voter into `authorized_voters`
+    // which `VoteStateVersions::is_uninitialized` erroneously reports as initialized
+    #[cfg(any(target_os = "solana", feature = "bincode"))]
+    pub fn deserialize(input: &[u8]) -> Result<Self, InstructionError> {
+        #[cfg(not(target_os = "solana"))]
+        {
+            bincode::deserialize::<VoteStateVersions>(input)
+                .map(|versioned| versioned.convert_to_v3())
+                .map_err(|_| InstructionError::InvalidAccountData)
+        }
+        #[cfg(target_os = "solana")]
+        {
+            let mut vote_state = Self::default();
+            Self::deserialize_into(input, &mut vote_state)?;
+            Ok(vote_state)
+        }
+    }
+
+    /// Deserializes the input `VoteStateVersions` buffer directly into the provided `VoteStateV3`.
+    ///
+    /// In a SBPF context, V0_23_5 is not supported, but in non-SBPF, all versions are supported for
+    /// compatibility with `bincode::deserialize`.
+    ///
+    /// On success, `vote_state` reflects the state of the input data. On failure, `vote_state` is
+    /// reset to `VoteStateV3::default()`.
+    #[cfg(any(target_os = "solana", feature = "bincode"))]
+    pub fn deserialize_into(
+        input: &[u8],
+        vote_state: &mut VoteStateV3,
+    ) -> Result<(), InstructionError> {
+        use super::vote_state_deserialize;
+        vote_state_deserialize::deserialize_into(input, vote_state, Self::deserialize_into_ptr)
+    }
+
+    /// Deserializes the input `VoteStateVersions` buffer directly into the provided
+    /// `MaybeUninit<VoteStateV3>`.
+    ///
+    /// In a SBPF context, V0_23_5 is not supported, but in non-SBPF, all versions are supported for
+    /// compatibility with `bincode::deserialize`.
+    ///
+    /// On success, `vote_state` is fully initialized and can be converted to
+    /// `VoteStateV3` using
+    /// [`MaybeUninit::assume_init`](https://doc.rust-lang.org/std/mem/union.MaybeUninit.html#method.assume_init).
+    /// On failure, `vote_state` may still be uninitialized and must not be
+    /// converted to `VoteStateV3`.
+    #[cfg(any(target_os = "solana", feature = "bincode"))]
+    pub fn deserialize_into_uninit(
+        input: &[u8],
+        vote_state: &mut std::mem::MaybeUninit<VoteStateV3>,
+    ) -> Result<(), InstructionError> {
+        VoteStateV3::deserialize_into_ptr(input, vote_state.as_mut_ptr())
+    }
+
+    #[cfg(any(target_os = "solana", feature = "bincode"))]
+    fn deserialize_into_ptr(
+        input: &[u8],
+        vote_state: *mut VoteStateV3,
+    ) -> Result<(), InstructionError> {
+        use super::vote_state_deserialize::deserialize_vote_state_into;
+
+        let mut cursor = std::io::Cursor::new(input);
+
+        let variant = solana_serialize_utils::cursor::read_u32(&mut cursor)?;
+        match variant {
+            // V0_23_5. not supported for bpf targets; these should not exist on mainnet
+            // supported for non-bpf targets for backwards compatibility
+            0 => {
+                #[cfg(not(target_os = "solana"))]
+                {
+                    // Safety: vote_state is valid as it comes from `&mut MaybeUninit<VoteStateV3>` or
+                    // `&mut VoteStateV3`. In the first case, the value is uninitialized so we write()
+                    // to avoid dropping invalid data; in the latter case, we `drop_in_place()`
+                    // before writing so the value has already been dropped and we just write a new
+                    // one in place.
+                    unsafe {
+                        vote_state.write(
+                            bincode::deserialize::<VoteStateVersions>(input)
+                                .map(|versioned| versioned.convert_to_v3())
+                                .map_err(|_| InstructionError::InvalidAccountData)?,
+                        );
+                    }
+                    Ok(())
+                }
+                #[cfg(target_os = "solana")]
+                Err(InstructionError::InvalidAccountData)
+            }
+            // V1_14_11. substantially different layout and data from V0_23_5
+            1 => deserialize_vote_state_into(&mut cursor, vote_state, false),
+            // V3. the only difference from V1_14_11 is the addition of a slot-latency to each vote
+            2 => deserialize_vote_state_into(&mut cursor, vote_state, true),
+            _ => Err(InstructionError::InvalidAccountData),
+        }?;
+
+        Ok(())
+    }
+
+    #[cfg(feature = "bincode")]
+    pub fn serialize(
+        versioned: &VoteStateVersions,
+        output: &mut [u8],
+    ) -> Result<(), InstructionError> {
+        bincode::serialize_into(output, versioned).map_err(|err| match *err {
+            bincode::ErrorKind::SizeLimit => InstructionError::AccountDataTooSmall,
+            _ => InstructionError::GenericError,
+        })
+    }
+
+    /// Returns if the vote state contains a slot `candidate_slot`
+    pub fn contains_slot(&self, candidate_slot: Slot) -> bool {
+        self.votes
+            .binary_search_by(|vote| vote.slot().cmp(&candidate_slot))
+            .is_ok()
+    }
+
+    #[cfg(test)]
+    pub(crate) fn get_max_sized_vote_state() -> VoteStateV3 {
+        use solana_epoch_schedule::MAX_LEADER_SCHEDULE_EPOCH_OFFSET;
+        let mut authorized_voters = AuthorizedVoters::default();
+        for i in 0..=MAX_LEADER_SCHEDULE_EPOCH_OFFSET {
+            authorized_voters.insert(i, Pubkey::new_unique());
+        }
+
+        VoteStateV3 {
+            votes: VecDeque::from(vec![LandedVote::default(); MAX_LOCKOUT_HISTORY]),
+            root_slot: Some(u64::MAX),
+            epoch_credits: vec![(0, 0, 0); MAX_EPOCH_CREDITS_HISTORY],
+            authorized_voters,
+            ..Self::default()
+        }
+    }
+
+    pub fn process_next_vote_slot(
+        &mut self,
+        next_vote_slot: Slot,
+        epoch: Epoch,
+        current_slot: Slot,
+        pop_expired: bool,
+    ) {
+        // Ignore votes for slots earlier than we already have votes for
+        if self
+            .last_voted_slot()
+            .is_some_and(|last_voted_slot| next_vote_slot <= last_voted_slot)
+        {
+            return;
+        }
+
+        if pop_expired {
+            self.pop_expired_votes(next_vote_slot);
+        }
+
+        let landed_vote = LandedVote {
+            latency: Self::compute_vote_latency(next_vote_slot, current_slot),
+            lockout: Lockout::new(next_vote_slot),
+        };
+
+        // Once the stack is full, pop the oldest lockout and distribute rewards
+        if self.votes.len() == MAX_LOCKOUT_HISTORY {
+            let credits = self.credits_for_vote_at_index(0);
+            let landed_vote = self.votes.pop_front().unwrap();
+            self.root_slot = Some(landed_vote.slot());
+
+            self.increment_credits(epoch, credits);
+        }
+        self.votes.push_back(landed_vote);
+        self.double_lockouts();
+    }
+
+    /// increment credits, record credits for last epoch if new epoch
+    pub fn increment_credits(&mut self, epoch: Epoch, credits: u64) {
+        // increment credits, record by epoch
+
+        // never seen a credit
+        if self.epoch_credits.is_empty() {
+            self.epoch_credits.push((epoch, 0, 0));
+        } else if epoch != self.epoch_credits.last().unwrap().0 {
+            let (_, credits, prev_credits) = *self.epoch_credits.last().unwrap();
+
+            if credits != prev_credits {
+                // if credits were earned previous epoch
+                // append entry at end of list for the new epoch
+                self.epoch_credits.push((epoch, credits, credits));
+            } else {
+                // else just move the current epoch
+                self.epoch_credits.last_mut().unwrap().0 = epoch;
+            }
+
+            // Remove too old epoch_credits
+            if self.epoch_credits.len() > MAX_EPOCH_CREDITS_HISTORY {
+                self.epoch_credits.remove(0);
+            }
+        }
+
+        self.epoch_credits.last_mut().unwrap().1 =
+            self.epoch_credits.last().unwrap().1.saturating_add(credits);
+    }
+
+    // Computes the vote latency for vote on voted_for_slot where the vote itself landed in current_slot
+    pub fn compute_vote_latency(voted_for_slot: Slot, current_slot: Slot) -> u8 {
+        std::cmp::min(current_slot.saturating_sub(voted_for_slot), u8::MAX as u64) as u8
+    }
+
+    /// Returns the credits to award for a vote at the given lockout slot index
+    pub fn credits_for_vote_at_index(&self, index: usize) -> u64 {
+        let latency = self
+            .votes
+            .get(index)
+            .map_or(0, |landed_vote| landed_vote.latency);
+
+        // If latency is 0, this means that the Lockout was created and stored from a software version that did not
+        // store vote latencies; in this case, 1 credit is awarded
+        if latency == 0 {
+            1
+        } else {
+            match latency.checked_sub(VOTE_CREDITS_GRACE_SLOTS) {
+                None | Some(0) => {
+                    // latency was <= VOTE_CREDITS_GRACE_SLOTS, so maximum credits are awarded
+                    VOTE_CREDITS_MAXIMUM_PER_SLOT as u64
+                }
+
+                Some(diff) => {
+                    // diff = latency - VOTE_CREDITS_GRACE_SLOTS, and diff > 0
+                    // Subtract diff from VOTE_CREDITS_MAXIMUM_PER_SLOT which is the number of credits to award
+                    match VOTE_CREDITS_MAXIMUM_PER_SLOT.checked_sub(diff) {
+                        // If diff >= VOTE_CREDITS_MAXIMUM_PER_SLOT, 1 credit is awarded
+                        None | Some(0) => 1,
+
+                        Some(credits) => credits as u64,
+                    }
+                }
+            }
+        }
+    }
+
+    pub fn nth_recent_lockout(&self, position: usize) -> Option<&Lockout> {
+        if position < self.votes.len() {
+            let pos = self
+                .votes
+                .len()
+                .checked_sub(position)
+                .and_then(|pos| pos.checked_sub(1))?;
+            self.votes.get(pos).map(|vote| &vote.lockout)
+        } else {
+            None
+        }
+    }
+
+    pub fn last_lockout(&self) -> Option<&Lockout> {
+        self.votes.back().map(|vote| &vote.lockout)
+    }
+
+    pub fn last_voted_slot(&self) -> Option<Slot> {
+        self.last_lockout().map(|v| v.slot())
+    }
+
+    // Upto MAX_LOCKOUT_HISTORY many recent unexpired
+    // vote slots pushed onto the stack.
+    pub fn tower(&self) -> Vec<Slot> {
+        self.votes.iter().map(|v| v.slot()).collect()
+    }
+
+    pub fn current_epoch(&self) -> Epoch {
+        if self.epoch_credits.is_empty() {
+            0
+        } else {
+            self.epoch_credits.last().unwrap().0
+        }
+    }
+
+    /// Number of "credits" owed to this account from the mining pool. Submit this
+    /// VoteStateV3 to the Rewards program to trade credits for lamports.
+    pub fn credits(&self) -> u64 {
+        if self.epoch_credits.is_empty() {
+            0
+        } else {
+            self.epoch_credits.last().unwrap().1
+        }
+    }
+
+    /// Number of "credits" owed to this account from the mining pool on a per-epoch basis,
+    ///  starting from credits observed.
+    /// Each tuple of (Epoch, u64, u64) is read as (epoch, credits, prev_credits), where
+    ///   credits for each epoch is credits - prev_credits; while redundant this makes
+    ///   calculating rewards over partial epochs nice and simple
+    pub fn epoch_credits(&self) -> &Vec<(Epoch, u64, u64)> {
+        &self.epoch_credits
+    }
+
+    pub fn set_new_authorized_voter<F>(
+        &mut self,
+        authorized_pubkey: &Pubkey,
+        current_epoch: Epoch,
+        target_epoch: Epoch,
+        verify: F,
+    ) -> Result<(), InstructionError>
+    where
+        F: Fn(Pubkey) -> Result<(), InstructionError>,
+    {
+        let epoch_authorized_voter = self.get_and_update_authorized_voter(current_epoch)?;
+        verify(epoch_authorized_voter)?;
+
+        // The offset in slots `n` on which the target_epoch
+        // (default value `DEFAULT_LEADER_SCHEDULE_SLOT_OFFSET`) is
+        // calculated is the number of slots available from the
+        // first slot `S` of an epoch in which to set a new voter for
+        // the epoch at `S` + `n`
+        if self.authorized_voters.contains(target_epoch) {
+            return Err(VoteError::TooSoonToReauthorize.into());
+        }
+
+        // Get the latest authorized_voter
+        let (latest_epoch, latest_authorized_pubkey) = self
+            .authorized_voters
+            .last()
+            .ok_or(InstructionError::InvalidAccountData)?;
+
+        // If we're not setting the same pubkey as authorized pubkey again,
+        // then update the list of prior voters to mark the expiration
+        // of the old authorized pubkey
+        if latest_authorized_pubkey != authorized_pubkey {
+            // Update the epoch ranges of authorized pubkeys that will be expired
+            let epoch_of_last_authorized_switch =
+                self.prior_voters.last().map(|range| range.2).unwrap_or(0);
+
+            // target_epoch must:
+            // 1) Be monotonically increasing due to the clock always
+            //    moving forward
+            // 2) not be equal to latest epoch otherwise this
+            //    function would have returned TooSoonToReauthorize error
+            //    above
+            if target_epoch <= *latest_epoch {
+                return Err(InstructionError::InvalidAccountData);
+            }
+
+            // Commit the new state
+            self.prior_voters.append((
+                *latest_authorized_pubkey,
+                epoch_of_last_authorized_switch,
+                target_epoch,
+            ));
+        }
+
+        self.authorized_voters
+            .insert(target_epoch, *authorized_pubkey);
+
+        Ok(())
+    }
+
+    pub fn get_and_update_authorized_voter(
+        &mut self,
+        current_epoch: Epoch,
+    ) -> Result<Pubkey, InstructionError> {
+        let pubkey = self
+            .authorized_voters
+            .get_and_cache_authorized_voter_for_epoch(current_epoch)
+            .ok_or(InstructionError::InvalidAccountData)?;
+        self.authorized_voters
+            .purge_authorized_voters(current_epoch);
+        Ok(pubkey)
+    }
+
+    // Pop all recent votes that are not locked out at the next vote slot.  This
+    // allows validators to switch forks once their votes for another fork have
+    // expired. This also allows validators continue voting on recent blocks in
+    // the same fork without increasing lockouts.
+    pub fn pop_expired_votes(&mut self, next_vote_slot: Slot) {
+        while let Some(vote) = self.last_lockout() {
+            if !vote.is_locked_out_at_slot(next_vote_slot) {
+                self.votes.pop_back();
+            } else {
+                break;
+            }
+        }
+    }
+
+    pub fn double_lockouts(&mut self) {
+        let stack_depth = self.votes.len();
+        for (i, v) in self.votes.iter_mut().enumerate() {
+            // Don't increase the lockout for this vote until we get more confirmations
+            // than the max number of confirmations this vote has seen
+            if stack_depth >
+                i.checked_add(v.confirmation_count() as usize)
+                    .expect("`confirmation_count` and tower_size should be bounded by `MAX_LOCKOUT_HISTORY`")
+            {
+                v.lockout.increase_confirmation_count(1);
+            }
+        }
+    }
+
+    pub fn process_timestamp(
+        &mut self,
+        slot: Slot,
+        timestamp: UnixTimestamp,
+    ) -> Result<(), VoteError> {
+        if (slot < self.last_timestamp.slot || timestamp < self.last_timestamp.timestamp)
+            || (slot == self.last_timestamp.slot
+                && BlockTimestamp { slot, timestamp } != self.last_timestamp
+                && self.last_timestamp.slot != 0)
+        {
+            return Err(VoteError::TimestampTooOld);
+        }
+        self.last_timestamp = BlockTimestamp { slot, timestamp };
+        Ok(())
+    }
+
+    pub fn is_correct_size_and_initialized(data: &[u8]) -> bool {
+        const VERSION_OFFSET: usize = 4;
+        const DEFAULT_PRIOR_VOTERS_END: usize = VERSION_OFFSET + DEFAULT_PRIOR_VOTERS_OFFSET;
+        data.len() == VoteStateV3::size_of()
+            && data[VERSION_OFFSET..DEFAULT_PRIOR_VOTERS_END] != [0; DEFAULT_PRIOR_VOTERS_OFFSET]
+    }
+}
diff --git a/vote-interface/src/state/vote_state_v4.rs b/vote-interface/src/state/vote_state_v4.rs
new file mode 100644
index 0000000000..1ca30d395c
--- /dev/null
+++ b/vote-interface/src/state/vote_state_v4.rs
@@ -0,0 +1,67 @@
+#[cfg(feature = "dev-context-only-utils")]
+use arbitrary::Arbitrary;
+#[cfg(feature = "serde")]
+use serde_derive::{Deserialize, Serialize};
+#[cfg(feature = "serde")]
+use serde_with::serde_as;
+#[cfg(feature = "frozen-abi")]
+use solana_frozen_abi_macro::{frozen_abi, AbiExample};
+use {
+    super::{BlockTimestamp, LandedVote, BLS_PUBLIC_KEY_COMPRESSED_SIZE},
+    crate::authorized_voters::AuthorizedVoters,
+    solana_clock::{Epoch, Slot},
+    solana_pubkey::Pubkey,
+    std::{collections::VecDeque, fmt::Debug},
+};
+
+#[cfg_attr(
+    feature = "frozen-abi",
+    frozen_abi(digest = "2H9WgTh7LgdnpinvEwxzP3HF6SDuKp6qdwFmJk9jHDRP"),
+    derive(AbiExample)
+)]
+#[cfg_attr(feature = "serde", cfg_eval::cfg_eval, serde_as)]
+#[cfg_attr(feature = "serde", derive(Deserialize, Serialize))]
+#[derive(Debug, Default, PartialEq, Eq, Clone)]
+#[cfg_attr(feature = "dev-context-only-utils", derive(Arbitrary))]
+pub struct VoteStateV4 {
+    /// The node that votes in this account.
+    pub node_pubkey: Pubkey,
+    /// The signer for withdrawals.
+    pub authorized_withdrawer: Pubkey,
+
+    /// The collector account for inflation rewards.
+    pub inflation_rewards_collector: Pubkey,
+    /// The collector account for block revenue.
+    pub block_revenue_collector: Pubkey,
+
+    /// Basis points (0-10,000) that represent how much of the inflation
+    /// rewards should be given to this vote account.
+    pub inflation_rewards_commission_bps: u16,
+    /// Basis points (0-10,000) that represent how much of the block revenue
+    /// should be given to this vote account.
+    pub block_revenue_commission_bps: u16,
+
+    /// Reward amount pending distribution to stake delegators.
+    pub pending_delegator_rewards: u64,
+
+    /// Compressed BLS pubkey for Alpenglow.
+    #[cfg_attr(
+        feature = "serde",
+        serde_as(as = "Option<[_; BLS_PUBLIC_KEY_COMPRESSED_SIZE]>")
+    )]
+    pub bls_pubkey_compressed: Option<[u8; BLS_PUBLIC_KEY_COMPRESSED_SIZE]>,
+
+    pub votes: VecDeque<LandedVote>,
+    pub root_slot: Option<Slot>,
+
+    /// The signer for vote transactions.
+    /// Contains entries for the current epoch and the previous epoch.
+    pub authorized_voters: AuthorizedVoters,
+
+    /// History of credits earned by the end of each epoch.
+    /// Each tuple is (Epoch, credits, prev_credits).
+    pub epoch_credits: Vec<(Epoch, u64, u64)>,
+
+    /// Most recent timestamp submitted with a vote.
+    pub last_timestamp: BlockTimestamp,
+}
diff --git a/vote-interface/src/state/vote_state_versions.rs b/vote-interface/src/state/vote_state_versions.rs
new file mode 100644
index 0000000000..5e918395ce
--- /dev/null
+++ b/vote-interface/src/state/vote_state_versions.rs
@@ -0,0 +1,120 @@
+#[cfg(test)]
+use arbitrary::{Arbitrary, Unstructured};
+use {
+    crate::{
+        authorized_voters::AuthorizedVoters,
+        state::{
+            vote_state_0_23_5::VoteState0_23_5, vote_state_1_14_11::VoteState1_14_11, CircBuf,
+            LandedVote, Lockout, VoteStateV3,
+        },
+    },
+    solana_pubkey::Pubkey,
+    std::collections::VecDeque,
+};
+
+#[cfg_attr(
+    feature = "serde",
+    derive(serde_derive::Deserialize, serde_derive::Serialize)
+)]
+#[derive(Debug, PartialEq, Eq, Clone)]
+pub enum VoteStateVersions {
+    V0_23_5(Box<VoteState0_23_5>),
+    V1_14_11(Box<VoteState1_14_11>),
+    V3(Box<VoteStateV3>),
+}
+
+impl VoteStateVersions {
+    pub fn new_v3(vote_state: VoteStateV3) -> Self {
+        Self::V3(Box::new(vote_state))
+    }
+
+    pub fn convert_to_v3(self) -> VoteStateV3 {
+        match self {
+            VoteStateVersions::V0_23_5(state) => {
+                let authorized_voters =
+                    AuthorizedVoters::new(state.authorized_voter_epoch, state.authorized_voter);
+
+                VoteStateV3 {
+                    node_pubkey: state.node_pubkey,
+
+                    authorized_withdrawer: state.authorized_withdrawer,
+
+                    commission: state.commission,
+
+                    votes: Self::landed_votes_from_lockouts(state.votes),
+
+                    root_slot: state.root_slot,
+
+                    authorized_voters,
+
+                    prior_voters: CircBuf::default(),
+
+                    epoch_credits: state.epoch_credits.clone(),
+
+                    last_timestamp: state.last_timestamp.clone(),
+                }
+            }
+
+            VoteStateVersions::V1_14_11(state) => VoteStateV3 {
+                node_pubkey: state.node_pubkey,
+                authorized_withdrawer: state.authorized_withdrawer,
+                commission: state.commission,
+
+                votes: Self::landed_votes_from_lockouts(state.votes),
+
+                root_slot: state.root_slot,
+
+                authorized_voters: state.authorized_voters.clone(),
+
+                prior_voters: state.prior_voters,
+
+                epoch_credits: state.epoch_credits,
+
+                last_timestamp: state.last_timestamp,
+            },
+
+            VoteStateVersions::V3(state) => *state,
+        }
+    }
+
+    fn landed_votes_from_lockouts(lockouts: VecDeque<Lockout>) -> VecDeque<LandedVote> {
+        lockouts.into_iter().map(|lockout| lockout.into()).collect()
+    }
+
+    pub fn is_uninitialized(&self) -> bool {
+        match self {
+            VoteStateVersions::V0_23_5(vote_state) => {
+                vote_state.authorized_voter == Pubkey::default()
+            }
+
+            VoteStateVersions::V1_14_11(vote_state) => vote_state.authorized_voters.is_empty(),
+
+            VoteStateVersions::V3(vote_state) => vote_state.authorized_voters.is_empty(),
+        }
+    }
+
+    pub fn vote_state_size_of(is_v3: bool) -> usize {
+        if is_v3 {
+            VoteStateV3::size_of()
+        } else {
+            VoteState1_14_11::size_of()
+        }
+    }
+
+    pub fn is_correct_size_and_initialized(data: &[u8]) -> bool {
+        VoteStateV3::is_correct_size_and_initialized(data)
+            || VoteState1_14_11::is_correct_size_and_initialized(data)
+    }
+}
+
+#[cfg(test)]
+impl Arbitrary<'_> for VoteStateVersions {
+    fn arbitrary(u: &mut Unstructured<'_>) -> arbitrary::Result<Self> {
+        let variant = u.choose_index(2)?;
+        match variant {
+            0 => Ok(Self::V3(Box::new(VoteStateV3::arbitrary(u)?))),
+            1 => Ok(Self::V1_14_11(Box::new(VoteState1_14_11::arbitrary(u)?))),
+            _ => unreachable!(),
+        }
+    }
+}
diff --git a/vote/benches/vote_account.rs b/vote/benches/vote_account.rs
index 6e0d3e70d0..d836c7abba 100644
--- a/vote/benches/vote_account.rs
+++ b/vote/benches/vote_account.rs
@@ -25,7 +25,7 @@ fn new_rand_vote_account<R: Rng>(
         unix_timestamp: rng.gen(),
     };
     let mut vote_state = VoteStateV3::new(&vote_init, &clock);
-    vote_state.process_next_vote_slot(0, 0, 1);
+    vote_state.process_next_vote_slot(0, 0, 1, true);
     let account = AccountSharedData::new_data(
         rng.gen(), // lamports
         &VoteStateVersions::new_v3(vote_state.clone()),
-- 
2.39.5 (Apple Git-154)

