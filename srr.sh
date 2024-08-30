#!/bin/bash
#
# Simulate the behaviour of Selfish Round Robin Scheduling Algorithm.
# Author: Muhammed Sahil Arayakandy
#

input=$1 # data file entered
a=$2 # priority increment for new queue
b=$3 # priority increment for accepted queue

q=1 # default quanta value

# Check number of parameters
if [[ $# -eq 3 ]]
then
  echo "Right number of parameters entered: $#"
elif [[ $# -eq 4 ]]
then
  echo "Right number of parameters entered: $#"
  q=$4 # assign user defined quanta value
else
  echo "Error! Incorrect number of parameters entered: $# (it should be 3 or 4)"
  exit
fi

# Check that the 2nd, 3rd & 4th parameters are numbers
str="$2$3$4"
nchar=${#str}

i=0
while [[ $i -lt $nchar ]]
do
    ch=${str:i:1}

    case $ch in
    0|1|2|3|4|5|6|7|8|9) numf=1
                        ;;
    *) numf=0
        break
        ;;
    esac

    ((i = $i + 1))
done

if test $numf = 1
then
    echo "digit match"
else
    echo "Error! 2nd, 3rd & 4th (Optional) Parameters have to be a number"
    exit
fi

# Check that input file is a regular file
if [[ -f $input ]]
then
  echo "$input data file entered"
else
  echo "Error! Input file needs to be a regular file"
  exit
fi

# Prompt the user for output choice
echo "*****************************"
echo "Please choose output option"
echo "*****************************"
echo "1 ... Standard Output Only"
echo "2 ... Named Text File Only"
echo "3 ... Both"
echo "****************************"

read -p "option : " option
echo "****************************"

if [[ $option -eq 1 ]]
then
  echo "Chosen Option: Standard Output Only"
elif [[ $option -eq 2 ]]
then
  echo "Chosen Option: Named Text File Only"
  read -p "Please enter the output file name: " fname
elif [[ $option -eq 3 ]]
then
  echo "Chosen Option: Both"
  read -p "Please enter the output file name: " fname
else
  echo "Invalid input for Option. Please enter a valid number."
  exit
fi


processes=() # raw processes

# read the input and build the processes array
while read -r id nut at
do
  processes[${#processes[@]}]="$id $nut $at"
done < $input

# print each item in array
for process in "${processes[@]}"
do
     echo "$process"
done

echo "Priority Increment in New_Queue = $a and in Accepted_Queue = $b"


#######################################
# Outputs the header to stdout
# Globals:
#   ${processes[@]}
# Arguments:
#   None
# Outputs:
#   Writes header to stdout
#######################################
function outputHeaderToStdOut {
  echo -e "T \t\c"
  for process in "${processes[@]}"
  do
    p=($process)
    echo -e "${p[0]}  \t\c"
  done
  echo -e "\n"
}

#######################################
# Outputs the header to file.
# Globals:
#   ${processes[@]}
# Arguments:
#   None
# Outputs:
#   Writes header to file
#######################################
function outputHeaderToFile {
  echo -e "T \t\c" > $fname
  for process in "${processes[@]}"
  do
    p=($process)
    echo -e "${p[0]}  \t\c" >> $fname
  done
  echo -e "\n" >> $fname
}

# Print the Headers for output
if [[ $option -eq 1 ]]
then
  outputHeaderToStdOut
elif [[ $option -eq 2 ]]
then
  outputHeaderToFile
elif [[ $option -eq 3 ]]
then
  outputHeaderToStdOut
  outputHeaderToFile
fi

# sort processes according to arrival time
i=0
nelem=${#processes[@]}

while [[ $i -lt $nelem ]]
do
  j=0
  while [[ $j -lt $nelem ]]
  do
    p1=(${processes[j]})
    at1=${p1[1]}
    
    p2=(${processes[j+1]})
    at2=${p2[1]}

    if [[ $at1 -lt $at2 ]]
    then
      processes[j]="${p2[@]}"
      processes[j+1]="${p1[@]}"
    fi
    
   ((j = $j + 1))
  done

  ((i = $i + 1))
done


# Core Algorithm

t=0 # time

newQ=() # the new queue
accQ=() # the accepted queue
finishedQ=() # the finished queue

while [[ true ]]
do
  # Add jobs based on the arrival time
  for process in "${processes[@]}"
  do
  p=($process)

  if [[ ${p[2]} -eq $t ]]
  then
      if [[ ${#newQ[@]} -eq 0 && ${#accQ[@]} -eq 0 ]]
      then
      accQ[${#accQ[@]}]="${p[0]} ${p[1]} ${p[2]} 0 -"
      else
      newQ[${#newQ[@]}]="${p[0]} ${p[1]} ${p[2]} 0 -"
      fi
  fi
  done


  # Make the status's of all jobs to 'W' (Waiting)
  for (( i = 0; i < ${#newQ[@]}; i++ ))
  do
    job=${newQ[i]}
    j=($job)

    j[4]="W"

    newQ[i]="${j[@]}"
  done

  for (( i = 0; i < ${#accQ[@]}; i++ ))
  do
    job=${accQ[i]}
    j=($job)

    j[4]="W"

    accQ[i]="${j[@]}"
  done


  # Set top job to 'R' and decrement the NUT
  if [[ ${#accQ[@]} -ne 0 ]]
  then
    job=${accQ[0]}
    j=($job)

    j[4]="R"

    nut=${j[1]}
    (( nut = $nut - 1 ))
    j[1]=$nut

    accQ[0]="${j[@]}"
  fi


  # Increment the priority of all jobs with user defined values
  for (( i = 0; i < ${#newQ[@]}; i++ ))
  do
    job=${newQ[i]}
    j=($job)

    pr=${j[3]}
    (( pr = $pr + $a ))
    j[3]=$pr

    newQ[i]="${j[@]}"
  done

  for (( i = 0; i < ${#accQ[@]}; i++ ))
  do
    job=${accQ[i]}
    j=($job)

    pr=${j[3]}
    (( pr = $pr + $b ))
    j[3]=$pr

    accQ[i]="${j[@]}"
  done


  # Move job on priority match
  accQPriorities=()
  lowestAccQPriority=0

  for (( i = 0; i < ${#accQ[@]}; i++ ))
  do
    job=${accQ[i]}
    j=($job)

    pr=${j[3]}
    accQPriorities+=($pr)
  done
  
  # get the lowest priority in accepted queue
  readarray -td '' sorted < <(printf '%s\0' "${accQPriorities[@]}" | sort -z)
  lowestAccQPriority=${sorted[0]}

  # find and move the jobs appropriately
  for (( i = 0; i < ${#newQ[@]}; i++ ))
  do
    job=${newQ[i]}
    j=($job)

    pr=${j[3]}

    if [[ $pr -ge $lowestAccQPriority ]]
    then
      unset newQ[$i]

      accQ[${#accQ[@]}]="${j[@]}"
    fi
  done

  newQ=("${newQ[@]}") # reindex the array after using unset


  # Apply Selfish Round Robin
  if [[ ${#accQ[@]} -ne 0 ]]
  then
    job=${accQ[0]}
    j=($job)

    nut=${j[1]}

    if [[ $nut -ne 0 ]]
    then
      unset accQ[0]
      accQ=("${accQ[@]}") # reindex the array after using unset

      accQ[${#accQ[@]}]="${j[@]}"
    fi
  fi


  # Print the Statuses
  statuses=()
  allJobs=( "${newQ[@]}" "${accQ[@]}" "${finishedQ[@]}" )

  for process in "${processes[@]}"
  do
    p=($process)
    pID=${p[0]}

    status="-"

    for job in "${allJobs[@]}"
    do
      j=($job)
      jID=${j[0]}

      if [[ "$pID" == "$jID" ]]
      then
        status=${j[4]}
      fi
    done

    statuses[${#statuses[@]}]=$status
  done
  
  #######################################
  # Outputs the statuses to stdout
  # Globals:
  #   ${statuses[@]}
  #   $t
  # Arguments:
  #   None
  # Outputs:
  #   Writes time and statuses to stdout
  #######################################
  function outputStatusesToStdOut {
    echo -e "$t \t\c"

    for status in "${statuses[@]}"
    do
      echo -e "$status  \t\c"
    done

    echo -e "\n"
  }

  #######################################
  # Outputs the statuses to file
  # Globals:
  #   ${statuses[@]}
  #   $t
  # Arguments:
  #   None
  # Outputs:
  #   Writes time and statuses to file
  #######################################
  function outputStatusesToFile {
    echo -e "$t \t\c" >> $fname
    
    for status in "${statuses[@]}"
    do
      echo -e "$status  \t\c"  >> $fname
    done

    echo -e "\n"  >> $fname
  }

  if [[ $option -eq 1 ]]
  then
    outputStatusesToStdOut
  elif [[ $option -eq 2 ]]
  then
    outputStatusesToFile
  elif [[ $option -eq 3 ]]
  then
    outputStatusesToStdOut
    outputStatusesToFile
  fi

  # Exit loop if all jobs have finished
  if [[ ${#finishedQ[@]} -eq ${#processes[@]} ]]
  then
    break
  fi


  # Move finished jobs to finished queue
  job=${accQ[0]}
  j=($job)
  
  nut=${j[1]}
  if [[ $nut -le 0 ]]
  then
    unset accQ[0]
    accQ=("${accQ[@]}")

    j[4]="F"
    finishedQ[${#finishedQ[@]}]="${j[@]}"
  fi
  
  # Increment t by 1
  (( t = $t + 1 ))
done

echo "Program Completed!"
exit
