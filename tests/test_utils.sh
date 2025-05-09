
function expect_file 
{
    if [[ ! -f "$1" ]]
    then
        echo "FAILED: File not found $1"
        pwd
        exit 1
    fi
}

function fail 
{
    echo "FAILED: $1"
    exit 1
}
