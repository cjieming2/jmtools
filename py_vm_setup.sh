#!/bin/bash
# ----------------------------------------------------------
# setup_project.sh
# Sets up a Python virtual environment in the current folder,
# installs essential packages, saves requirements.txt, and
# adds .venv/ to .gitignore.
#
# Usage:
#   1. Place this script in your project folder.
#   2. Make it executable: chmod +x setup_project.sh
#   3. Run it: py_vm_setup.sh
# ----------------------------------------------------------

# Check if Python3 is installed
if ! command -v python3 &> /dev/null; then
    echo "Python3 is not installed. Please install Python3 first."
    exit 1
fi

# Check if .venv exists
# prefix . so that it's hidden
if [ -d ".venv" ]; then
    echo ".venv directory already exists."
    exit 0   # stops the script here
else
    echo "Creating virtual environment in .venv ..."
    python3 -m venv .venv
fi

# Activate the virtual environment
source .venv/bin/activate

# Upgrade pip within vm
echo "Upgrading pip..."
pip install --upgrade pip

# Install packages within vm
echo "Installing numpy, pandas, matplotlib, jupyter..."
pip install numpy pandas matplotlib jupyter

# Save installed packages to requirements.txt
echo "Saving packages to requirements.txt..."
pip freeze > requirements.txt

# Add .venv to .gitignore if not already present
if grep -qxF ".venv/" .gitignore 2>/dev/null; then
    echo ".venv/ already in .gitignore"
else
    echo "Adding .venv/ to .gitignore"
    echo ".venv/" >> .gitignore
fi

echo "Setup complete! To activate the environment later, run:"
echo "source .venv/bin/activate"
echo "To start Jupyter Notebook, run:"
echo "jupyter notebook"

