import subprocess
import os
import json
from contextlib import contextmanager

def find_files_with_changes(old, new):
    cmd = ["git", "diff", "--name-only", old, new]
    result = subprocess.run(
        cmd,
        shell=False,
        check=True,
        capture_output=True,
    )
    output_str = result.stdout.decode()
    error_str = result.stderr.decode()
    if len(error_str):
        print(error_str)

    files_with_changes = output_str.splitlines()
    return files_with_changes

def set_git_user(user, email):
    subprocess.check_output(['git', 'config', '--global', 'user.email', email])
    subprocess.check_output(['git', 'config', '--global', 'user.name', user])



@contextmanager
def github_user_ctx(user, email, bypass=False):

    if not bypass:

        current_user_email = subprocess.check_output(['git', 'config', '--get', 'user.email']).decode('utf-8').strip()
        current_user_name = subprocess.check_output(['git', 'config', '--get', 'user.name']).decode('utf-8').strip()

        # set  new user
        set_git_user(user, email)

    try:
        yield
    finally:
        if not bypass:
            # restore user
            subprocess.check_output(['git', 'config', '--global', 'user.email', current_user_email])
            subprocess.check_output(['git', 'config', '--global', 'user.name', current_user_name])


@contextmanager
def bot_github_user_ctx(bypass=False):
    with github_user_ctx('emscripten-forge-bot', 'emscripten-forge-bot@users.noreply.github.com', bypass=bypass):
        yield

def set_bot_user():
    set_git_user('emscripten-forge-bot', 'emscripten-forge-bot@users.noreply.github.com')


def get_current_branch_name():
    return subprocess.check_output(['git', 'rev-parse', '--abbrev-ref', 'HEAD']).decode('utf-8').strip()


@contextmanager
def git_branch_ctx(new_branch_name, stash_current=True,  auto_delete=True):

    old_branch_name = get_current_branch_name()


    #  stash current changes and check return code
    stashed_successfully = False
    if stash_current:

        out = subprocess.run(['git', 'stash'], check=False)
        if out.returncode == 0:
            stashed_successfully = True


    
    subprocess.check_output(['git', 'checkout', '-b', new_branch_name])


    try:
        yield
    finally:
        subprocess.check_output(['git', 'checkout', old_branch_name, "--force"])

        # unstash changes
        if stash_current and stashed_successfully:
            subprocess.check_output(['git', 'stash', 'pop'])

        if auto_delete:
            subprocess.check_output(['git', 'branch', '-D', new_branch_name])


def automerge_is_enabled(pr):
    """Check if automerge is enabled for a specific PR."""
    labels = json.loads(subprocess.check_output(['gh', 'pr', 'view', str(pr), '--json', 'labels']).decode('utf-8'))['labels']

    return 'Automerge' in [label['name'] for label in labels]



def make_pr_for_recipe(recipe_dir, pr_title, target_branch_name, branch_name, automerge):

    # git commit
    subprocess.check_output(['git', 'add', recipe_dir])
    subprocess.check_output(['git', 'commit', '-m', pr_title])
    subprocess.check_output(['git', 'push', '-u', 'origin', branch_name, "--force"])

    # gh set default repo
    subprocess.check_call(['gh', 'repo', 'set-default', 'emscripten-forge/recipes'], cwd=os.getcwd())


    args = ['gh', 'pr', 'create',
            '-B', target_branch_name,
            '--title', pr_title, '--body', 'Beep-boop-beep! Whistle-whistle-woo!',
            '--label', 'Automerge' if automerge else 'Needs Tests'
    ]

    if target_branch_name == "emscripten-4x"
        args.extend(['--label', '4.X'])

    # call gh to create a PR
    subprocess.check_call(args, cwd=os.getcwd())
