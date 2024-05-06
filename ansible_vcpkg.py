#!/usr/local/anaconda3/bin/python


from __future__ import (absolute_import, division, print_function)
__metaclass__ = type

# Module documentation
DOCUMENTATION = """
---
module: my_test
short_description: Installs dependencies using Vcpkg package manager
version_added: "1.0.0"
description: >
    This Ansible module installs dependencies using the Vcpkg package manager.
    It clones the Vcpkg repository, optionally checks out a baseline, bootstraps Vcpkg,
    and installs specified dependencies.
options:
    x-vcpkg-asset-sources:
        description: >
            Specifies the Vcpkg asset sources.
        required: false
        type: str
        default: "x-azurl,file:///Users/mchlrtkwski/Desktop/ansible_vcpkg/cache/,,readwrite"
    binarysource:
        description: >
            Specifies the binary sources.
        required: false
        type: str
        default: "files,/Users/mchlrtkwski/Desktop/ansible_vcpkg/compiled/,readwrite"
    x-install-root:
        description: >
            Specifies the installation root directory.
        required: false
        type: str
        default: "/Users/mchlrtkwski/Desktop/ansible_vcpkg/installed"
    vcpkg-tools-reference:
        description: >
            Specifies the Vcpkg tools reference.
        required: false
        type: str
    default-registry:
        description: >
            Specifies the default Vcpkg registry.
        required: false
        type: dict
        default:
            repository: "https://github.com/microsoft/vcpkg.git"
            baseline: ""
    registries:
        description: >
            Specifies additional Vcpkg registries.
        required: false
        type: list
        default: []
    dependencies:
        description: >
            Specifies the list of dependencies to install.
        required: false
        type: list
        default: ["gtest", "protobuf", "boost"]
author:
    - Your Name (@yourGitHubHandle)
"""

# Examples of module usage
EXAMPLES = """
# Install dependencies
- name: Install dependencies using Vcpkg
  my_namespace.my_collection.my_test:
    dependencies:
      - gtest
      - protobuf
      - boost
"""

# Return values of the module
RETURN = """
original_message:
    description: The original name param that was passed in.
    type: str
    returned: always
    sample: 'hello world'
message:
    description: The output message that the test module generates.
    type: str
    returned: always
    sample: 'goodbye'
"""

from ansible.module_utils.basic import AnsibleModule
import subprocess
import shlex
import shutil
import tempfile
import os
import json

def run_module():
    # define available arguments/parameters a user can pass to the module
    #############################################################################################
    module_args = {
        "x-vcpkg-asset-sources": {
            "type": "str",
            "required": False,
            "default": "x-azurl,file:///Users/mchlrtkwski/Desktop/ansible_vcpkg/cache/,,readwrite"
        },
        "binarysource": {
            "type": "str",
            "required": False,
            "default": "files,/Users/mchlrtkwski/Desktop/ansible_vcpkg/compiled/,readwrite"
        },
        "x-install-root": {
            "type": "str",
            "required": False,
            "default": "/Users/mchlrtkwski/Desktop/ansible_vcpkg/installed"
        },
        "vcpkg-tools-reference": {
            "type": "str",
            "required": False
        },
        "default-registry": {
            "type": "dict",
            "required": False, 
            "default": {
                "repository": "https://github.com/microsoft/vcpkg.git",
                "baseline": ""
            }
        },
        "registries": {
            "type": "list",
            "required": False,
            "default": [] 
        },
        "dependencies": {
            "type": "list",
            "required": False,
            "default": [
                "gtest",
                "protobuf",
                "boost",
                "opencv"
            ]
        }
    }
    #############################################################################################
    # Define functions to be used in the module
    #############################################################################################

    def write_vcpkg_json(dependencies, fpath, return_dictionary):
        if not return_dictionary['failed']:
            # Create a new dictionary with key "dependencies" and value of the dependencies list
            dependencies_dict = {"dependencies": dependencies}
            # Open up the fpath and write the dependencies dictionary to the file as json
            with open(fpath, "w") as f:
                f.write(json.dumps(dependencies_dict))

    def write_vcpkg_configurations(default_registry, registries_list, fpath, return_dictionary):
        if not return_dictionary['failed']:
            # Create a new dictionary with keys "default-registry" and "registries" and values of the default_registry and registries_list
            configurations_dict = {"default-registry": default_registry, "registries": registries_list}
            # Open up the fpath and write the configurations dictionary to the file as json
            with open(fpath, "w") as f:
                f.write(json.dumps(configurations_dict))

    def validate_root_installation_path(installation_path, return_dictionary):
        if not return_dictionary['failed']:
            # Check to see if the installation path is a valid path
            if not os.path.exists(os.path.abspath(installation_path)):
                # Exit and return that the installation path is not valid
                return_dictionary['failed'] = True
                return_dictionary['msg'] = "Not a Path: {}".format(installation_path)
            return "--x-install-root={}".format(installation_path)

    def instantiate_shell_environment(asset_cache_endpoint, binary_cache_endpoint):
        env = os.environ.copy()
        if asset_cache_endpoint:
            env['X_VCPKG_ASSET_SOURCES'] = asset_cache_endpoint
        if binary_cache_endpoint:
            env['VCPKG_BINARY_SOURCES'] = binary_cache_endpoint
        return env

    def validate_baseline_reference(baseline_reference, return_dictionary):
        if not return_dictionary['failed']:
            baseline = baseline_reference if "baseline" in module.params["default-registry"] else ""
            # Check to see if the baseline contains any spaces
            if " " in baseline:
                # Exit and return that the baseine reference is not valid
                return_dictionary['failed'] = True
                return_dictionary['msg'] = "Baseline reference is not valid. Please provide a valid baseline reference."
            return baseline
        else:
            return ""

    def rereference_vcpkg_tools(vcpkg_directory, return_dictionary):
        pass

    def run_shell_action(command, shell_env, working_directory, return_dictionary):
        if not return_dictionary['failed']:
            try:
                process = subprocess.Popen(shlex.split(command), stdout=subprocess.PIPE, stderr=subprocess.PIPE, cwd=working_directory, env=shell_env)
                stdout, stderr = process.communicate()
                if process.returncode != 0:
                    return_dictionary['failed'] = True
                    return_dictionary['stdout'] = stdout.decode() if stdout else ''
                    return_dictionary['stderr'] = stderr.decode() if stderr else ''
                    return_dictionary['rc'] = process.returncode
            except Exception as e:
                return_dictionary['failed'] = True
                return_dictionary['msg'] = "Failed to execute command: {}".format(str(command))

    #############################################################################################
    # The main logic of the module
    #############################################################################################

    # seed the result dict in the object
    result = dict(
        failed=False,
        changed=False,
        original_message='',
        message=''
    )

    module = AnsibleModule(
        argument_spec=module_args,
        supports_check_mode=True
    )
    if module.check_mode:
        module.exit_json(**result)


    temp_dir = tempfile.mkdtemp()
    git_dir = os.path.join(temp_dir, "vcpkg")
    os.makedirs(git_dir, exist_ok=True)

    shell_environment = instantiate_shell_environment(module.params['x-vcpkg-asset-sources'], module.params['binarysource'])
    run_shell_action("git --version", shell_environment, git_dir, result)
    default_baseline = validate_baseline_reference(module.params['default-registry']["baseline"], result)
    installation_path = validate_root_installation_path(module.params['x-install-root'], result)

    run_shell_action("git clone {} {}".format(module.params['default-registry']["repository"], git_dir), shell_environment, git_dir, result)
    if default_baseline:
        run_shell_action("git checkout {}".format(default_baseline), shell_environment, git_dir, result)
    if module.params["vcpkg-tools-reference"]:
        rereference_vcpkg_tools(git_dir, result)
    run_shell_action("./bootstrap-vcpkg.sh", shell_environment, git_dir, result)
    write_vcpkg_configurations(module.params['default-registry'], module.params['registries'], os.path.join(git_dir, "vcpkg-configurations.json"), result)
    write_vcpkg_json(module.params["dependencies"], os.path.join(git_dir, "vcpkg.json"), result)
    run_shell_action("./vcpkg {} install".format(installation_path), shell_environment, git_dir, result)
    # Remove Temporary Directory
    shutil.rmtree(temp_dir, ignore_errors=True)

    result['original_message'] = "Test message"
    result['message'] = 'goodbye'

    module.exit_json(**result)


def main():
    run_module()


if __name__ == '__main__':
    main()

