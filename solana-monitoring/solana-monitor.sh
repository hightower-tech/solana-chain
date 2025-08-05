#!/bin/bash
#set -x # uncomment to enable debug

#####    Packages required: jq, bc
#####    Solana Validator Monitoring Script v.0.1 to be used with Node exporter -> Prometheus -> Grafana 
#####    Fetching data from Solana validator then output metrics to the node exporter text file
#####    Created: 14 Jan 08:44 CET 2025 by Htw.tech. Forked from Stakeconomy.com InfluxDB version that forked from original Zabbix nodemonitor.sh script created by Stakezone

#####    CONFIG    ##################################################################################################
#
# You must specify identityPubkey and votePubkey or specify the full path to the appropriate key files.
#
# Identity public key for the validator
identityPubkey=""
# Vote account public key  for the validator
votePubkey=""
# Identity Public key file i.e. /home/solana/validator-keypair.json
identityPubkeyFile=""
# Vote account Public key file  i.e. /home/solana/vote-keypair.json
votePubkeyFile=""
# Solana binary directory i.e. /root/.local/share/solana/install/active-release/bin
binDir=""
# RPC url. Default is localhost with port number 8899, alternatively it can be specified like http://custom.rpc.com:port i.e. https://api.mainnet-beta.solana.com https://api.testnet.solana.com/ 
rpcURL=""
# Amounts shown in 'SOL' instead of lamports
format="SOL"
# Time zone for epoch ends metric
timezone="UTC"
# The directory output of the Prometeus metrics file
metricsFile="/var/lib/node_exporter/solana_validator_metrics.prom"
#####  END CONFIG  ##################################################################################################

now=$(date +%s%3N)

solana_validator_status="NaN"
solana_validator_rootSlot="NaN"
solana_validator_lastVote="NaN"
solana_validator_leaderSlots="NaN"
solana_validator_skippedSlots="NaN"
solana_validator_pctSkipped="NaN"
solana_validator_pctTotSkipped="NaN"
solana_validator_pctSkippedDelta="NaN"
solana_validator_pctTotDelinquent="NaN"
solana_validator_version="NaN"
solana_validator_pctNewerVersions="NaN"
solana_validator_commission="NaN"
solana_validator_activatedStake="NaN"
solana_validator_credits="NaN"
solana_validator_epochCredits="NaN"
solana_validator_validatorBalance="NaN"
solana_validator_validatorVoteBalance="NaN"
solana_validator_epoch="NaN"
solana_validator_pctEpochElapsed="NaN"
solana_validator_epochCreditsMax="NaN"
solana_validator_slotIndex="NaN"
solana_validator_epochEnds="NaN"
solana_validator_tps="NaN"
solana_validator_rootDistance="NaN"
solana_validator_voteDistance="NaN"
solana_validator_timeStamp="NaN"

if [ -n "$binDir" ]; then
   cli="${binDir}/solana"
else
   echo "Please configure the cli"
   exit 1
fi


if [ -z "$rpcURL" ]; then
   rpcURL="http://127.0.0.1:8899"
fi


if [ -z "$identityPubkey" ]; then
   identityPubkey=$($cli address -k $identityPubkeyFile)
fi

if [ -z "$identityPubkey" ]; then
   echo "Please set identityPubkey or identityPubkeyFile "
fi

if [ -z "$votePubkey" ]; then
   votePubkey=$($cli address -k $votePubkeyFile)
fi

if [ -z "$votePubkey" ]; then
   echo "Please set votePubkey or votePubkeyFile"
   exit 1
fi


validatorBalance=$($cli balance --url $rpcURL $identityPubkey | grep -o '[0-9.]*')
validatorVoteBalance=$($cli balance --url $rpcURL $votePubkey | grep -o '[0-9.]*')

validatorCheck=$($cli validators --url $rpcURL | grep $identityPubkey)

if [ $(grep -c $votePubkey <<< $validatorCheck) == 0  ]; then echo "validator not found in set"; exit 1; fi

validators=$($cli validators --url $rpcURL --output json-compact 2>&-)
currentValidatorInfo=$(jq -r '.validators[] | select(.voteAccountPubkey == '\"$votePubkey\"')' <<<$validators)
delinquentValidatorInfo=$(jq -r '.validators[] | select(.voteAccountPubkey == '\"$votePubkey\"' and .delinquent == true)' <<<$validators)

if [[ ((-n "$currentValidatorInfo" || "$delinquentValidatorInfo" ))  ]]; then
   status=1 #status 0=validating 1=up 2=error 3=delinquent 4=stopped
   if [ -n "$blockHeightTime" ]; then blockHeightFromNow=$(expr $(date +%s) - $blockHeightTime); fi
   if [ -n "$delinquentValidatorInfo" ]; then
      status=3
      activatedStake=$(jq -r '.activatedStake' <<<$delinquentValidatorInfo)
      if [ "$format" == "SOL" ]; then activatedStake=$(echo "scale=2 ; $activatedStake / 1000000000.0" | bc); fi
      credits=$(jq -r '.credits' <<<$delinquentValidatorInfo)
      version=$(jq -r '.version' <<<$delinquentValidatorInfo | sed 's/ /-/g')
      version2=${version//./}
      commission=$(jq -r '.commission' <<<$delinquentValidatorInfo)
      rootSlot=$(jq -r '.rootSlot' <<<$delinquentValidatorInfo)
      lastVote=$(jq -r '.lastVote' <<<$delinquentValidatorInfo)
   elif [ -n "$currentValidatorInfo" ]; then
        status=0
        activatedStake=$(jq -r '.activatedStake' <<<$currentValidatorInfo)
        credits=$(jq -r '.credits' <<<$currentValidatorInfo)
        epochCredits=$(jq -r '.epochCredits' <<<$currentValidatorInfo)
        version=$(jq -r '.version' <<<$currentValidatorInfo | sed 's/ /-/g')
        version2=${version//./}
        commission=$(jq -r '.commission' <<<$currentValidatorInfo)
        rootSlot=$(jq -r '.rootSlot' <<<$currentValidatorInfo)
        lastVote=$(jq -r '.lastVote' <<<$currentValidatorInfo)
        rootDistance=$(echo "$validatorCheck" | grep $identityPubkey | grep -oP '\(\s*-?\d+\)' | tr -d '() ' | sed -n '2p')
        voteDistance=$(echo "$validatorCheck" | grep $identityPubkey | grep -oP '\(\s*-?\d+\)' | tr -d '() ' | head -n1)
        totalActiveStake=$(jq -r '.totalActiveStake' <<<$validators)
        totalDelinquentStake=$(jq -r '.totalDelinquentStake' <<<$validators)
        pctTotDelinquent=$(echo "scale=2 ; 100 * $totalDelinquentStake / $totalActiveStake" | bc)
        read leaderSlots skippedSlots <<<$($cli block-production | grep $identityPubkey | awk '{print $2,$4}')
        read totalBlocksProduced totalSlotsSkipped  <<<$($cli block-production | grep total | awk '{print $4,$6}')
        if [ "$format" == "SOL" ]; then activatedStake=$(echo "scale=2 ; $activatedStake / 1000000000.0" | bc); fi
        if [ -n "$leaderSlots" ]; then pctSkipped=$(echo "scale=2 ; 100 * $skippedSlots / $leaderSlots" | bc); fi
        if [ -z "$leaderSlots" ]; then leaderSlots=0 skippedSlots=0 pctSkipped=0; fi
        if [ -n "$totalBlocksProduced" ]; then
           pctTotSkipped=$(echo "scale=2 ; 100 * $totalSlotsSkipped / $totalBlocksProduced" | bc)
           pctSkippedDelta=$(echo "scale=2 ; 100 * ($pctSkipped - $pctTotSkipped) / $pctTotSkipped" | bc)
        fi
        if [ -z "$pctTotSkipped" ]; then pctTotSkipped=0 pctSkippedDelta=0; fi
   else status=2; fi
   epochInfo=$($cli epoch-info --url $rpcURL --output json )
   epoch=$(echo "$epochInfo" | jq '.epoch')
   slotIndex=$(echo "$epochInfo" | jq '.slotIndex')
   pctEpochElapsed=$(echo "$epochInfo" | jq '.epochCompletedPercent')
   tps=$(echo "$epochInfo" | jq '.transactionCount')
#   read validatorCreditsCurrent epochCreditsMax <<< $( $cli vote-account $votePubkey --url $rpcURL |  grep "credits/max credits" |  head -n 1 | cut -d ":" -f 2 | tr "/" " ")
   TIME=$($cli epoch-info --url $rpcURL | grep "Epoch Completed Time" | cut -d "(" -f 2 | awk '{print $1,$2,$3,$4}')
   VAR1=$(echo $TIME | grep -oE '[0-9]+day' | grep -o -E '[0-9]+')
   VAR2=$(echo $TIME | grep -oE '[0-9]+h'   | grep -o -E '[0-9]+')
   VAR3=$(echo $TIME | grep -oE '[0-9]+m'   | grep -o -E '[0-9]+')
   VAR4=$(echo $TIME | grep -oE '[0-9]+s'   | grep -o -E '[0-9]+')
   if [ -z "$VAR1" ]; then VAR1=0; fi
   if [ -z "$VAR2" ]; then VAR2=0; fi
   if [ -z "$VAR3" ]; then VAR3=0; fi
   if [ -z "$VAR4" ]; then VAR4=0; fi
   epochEnds=$(TZ=$timezone date -d "$VAR1 days $VAR2 hours $VAR3 minutes $VAR4 seconds" +"%m/%d/%Y %H:%M")
   epochEnds=$(( $(TZ=$timezone date -d "$epochEnds" +%s) * 1000 ))
else
  status=2
fi

{
    for item in \
      "solana_validator_status:$status" \
      "solana_validator_rootSlot:$rootSlot" \
      "solana_validator_lastVote:$lastVote" \
      "solana_validator_leaderSlots:$leaderSlots" \
      "solana_validator_skippedSlots:$skippedSlots" \
      "solana_validator_pctSkipped:$pctSkipped" \
      "solana_validator_pctTotSkipped:$pctTotSkipped" \
      "solana_validator_pctSkippedDelta:$pctSkippedDelta" \
      "solana_validator_pctTotDelinquent:$pctTotDelinquent" \
      "solana_validator_version:$version2" \
      "solana_validator_pctNewerVersions:$pctNewerVersions" \
      "solana_validator_commission:$commission" \
      "solana_validator_activatedStake:$activatedStake" \
      "solana_validator_credits:$credits" \
      "solana_validator_epochCredits:$epochCredits" \
      "solana_validator_validatorBalance:$validatorBalance" \
      "solana_validator_validatorVoteBalance:$validatorVoteBalance" \
      "solana_validator_nodes:$nodes" \
      "solana_validator_epoch:$epoch" \
      "solana_validator_pctEpochElapsed:$pctEpochElapsed" \
      "solana_validator_slotIndex:$slotIndex" \
      "solana_validator_epochEnds:$epochEnds" \
      "solana_validator_tps:$tps" \
      "solana_validator_rootDistance:$rootDistance" \
      "solana_validator_voteDistance:$voteDistance" \
      "solana_validator_timeStamp:$now"
    do
        key=${item%%:*}
        val=${item#*:}
        [[ -z $val || $val == *NaN* ]] && continue
        printf '%s %s\n' "$key" "$val"
    done
} > $metricsFile
