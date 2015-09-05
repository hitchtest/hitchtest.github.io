#!/bin/sh
set -e

echo "Installing and initializing hitch..."

help() {
    echo "If you need help or you think this script has a problem, please raise an issue at https://github.com/hitchtest/hitch/issues"
    echo "If you want to figure out how to install manually, try looking at https://hitchtest.readthedocs.org/en/latest/faq/install.html"
}

command_exists() {
    command -v "$@" > /dev/null 2>&1
}

checkpythonenvironment() {
    which python > /dev/null
    if [ $? != 0 ]; then
        echo "Python must be installed in order to install hitch."
        help
        exit 1
    fi

    which python3 > /dev/null
    if [ $? != 0 ]; then
        echo "Python 3 (with the name python3) must be installed in order to install hitch."
        help
        exit 1
    fi

    which pip > /dev/null
    if [ $? != 0 ]; then
       echo "pip must be installed in order to install hitch."
       help
       exit 1
    fi

    which virtualenv > /dev/null
    if [ $? != 0 ]; then
       echo "virtualenv must be installed in order to install hitch."
       help
       exit 1
    fi

    FULLVER=$(python -c 'import sys; print(sys.version)')
    DOTVERSION=$(expr substr "$FULLVER" 1 3)
    VERSION=$(expr substr "$DOTVERSION" 1 1)$(expr substr "$DOTVERSION" 3 3)
    if [ $VERSION -lt 26 ]; then
       echo "Hitch will not work on versions of python < 2.6 (or versions 3.0 -> 3.2)"
       echo "Try upgrading your system to the latest possible version and then try running this script again."
       help
       exit 1
    fi

    FULLVER=$(python3 -c 'import sys; print(sys.version)')
    DOTVERSION=$(expr substr "$FULLVER" 1 3)
    VERSION=$(expr substr "$DOTVERSION" 1 1)$(expr substr "$DOTVERSION" 3 3)
    if [ $VERSION -gt 30 ] && [ $VERSION -lt 33 ]; then
       echo "Hitch will not work on python 3 versions below 3.3"
       echo "Try upgrading your system to the latest possible version and then try again."
       echo "If you need help, try raising an issue at https://github.com/hitchtest/hitch/issues"
       exit 1
    fi
}

initandrun() {
    hitch clean
    hitch init

    if [ "$(find . -name *.test)" != "" ]; then
        hitch test .
        echo "Initialization complete. You can run all the tests by running the following command in this directory:"
        echo hitch test .
    else
        echo "Initialization complete. You can now write some tests!"
    fi
}

if [ "$(uname)" == "Darwin" ]; then
    which brew
    if [ $? == 0 ]; then
        for pkg in python python3 ; do
            if brew list -1 | grep -q "^${pkg}\$"; then
                echo "Package '$pkg' is installed"
            else
                brew install python python3
            fi
        done
        pip install --upgrade pip setuptools virtualenv
        pip install --upgrade hitch
        checkpythonenvironment
        initandrun
    else
        echo Hitch requires brew to be installed to run on the Mac.
        exit 1
    fi
elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
    lsb_dist=''
    if command_exists lsb_release; then
        lsb_dist="$(lsb_release -si)"
    fi
    if [ -z "$lsb_dist" ] && [ -r /etc/lsb-release ]; then
        lsb_dist="$(. /etc/lsb-release && echo "$DISTRIB_ID")"
    fi
    if [ -z "$lsb_dist" ] && [ -r /etc/debian_version ]; then
        lsb_dist='debian'
    fi
    if [ -z "$lsb_dist" ] && [ -r /etc/fedora-release ]; then
        lsb_dist='fedora'
    fi
    if [ -z "$lsb_dist" ] && [ -r /etc/oracle-release ]; then
        lsb_dist='oracleserver'
    fi
    if [ -z "$lsb_dist" ] && [ -r /etc/arch-release ]; then
        lsb_dist='arch'
    fi
    if [ -z "$lsb_dist" ] && [ -r /etc/gentoo-release ]; then
        lsb_dist='gentoo'
    fi
    if [ -z "$lsb_dist" ] && [ -r /etc/suse-release ]; then
        lsb_dist='suse'
    fi
    if [ -z "$lsb_dist" ]; then
        if [ -r /etc/centos-release ] || [ -r /etc/redhat-release ]; then
            lsb_dist='centos'
        fi
    fi
    if [ -z "$lsb_dist" ] && [ -r /etc/os-release ]; then
        lsb_dist="$(. /etc/os-release && echo "$ID")"
    fi

    lsb_dist="$(echo "$lsb_dist" | tr '[:upper:]' '[:lower:]')"

    case "$lsb_dist" in
        ubuntu|debian)
            dpkg --status python python-dev python-setuptools python-virtualenv python3 > /dev/null 2>&1
            if [ $? != 0 ]; then
                echo I need to run:
                echo "sudo apt-get install python python-dev python-setuptools python-virtualenv python3"
                sudo apt-get install python python3 python-dev python-setuptools python-virtualenv
            fi
        ;;

        fedora|redhat|centos)
            rpm -q python python-dev python-setuptools python-virtualenv python3 > /dev/null 2>&1
            if [ $? != 0 ]; then
                echo I need to run:
                echo "sudo yum install python python-devel python-setuptools python-virtualenv python3"
                sudo yum install python python-devel python-setuptools python-virtualenv python3
            fi
        ;;
    esac

    checkpythonenvironment
    which pipsi > /dev/null
    if [ $? != 0 ]; then
        pipsi install --upgrade hitch
    else
        echo "This will install/upgrade a single, small package with no dependencies:"
        echo sudo pip install --upgrade hitch
        sudo pip install -U hitch
    fi
    initandrun
else
    echo Hitch has not been tested on "$(uname)".
    echo If this is a UNIX system and you think it probably should work,
    echo please raise an issue at https://github.com/hitchtest/hitch/issues/
    help
    exit 1
fi
