import subprocess

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

# @contextmanager
# def bot_github_user_ctx():
    

#     # current_user_email = subprocess.check_output(['git', 'config', '--get', 'user.email']).decode('utf-8').strip()
#     # current_user_name = subprocess.check_output(['git', 'config', '--get', 'user.name']).decode('utf-8').strip()

#     # # set bot user
#     # subprocess.check_output(['git', 'config', '--global', 'user.email', 'emscripten-forge-bot@users.noreply.github.com'])
#     # subprocess.check_output(['git', 'config', '--global', 'user.name', 'emscripten-forge-bot'])

#     try:
#         yield


@contextmanager
def github_user_ctx(user, email):
    current_user_email = subprocess.check_output(['git', 'config', '--get', 'user.email']).decode('utf-8').strip()
    current_user_name = subprocess.check_output(['git', 'config', '--get', 'user.name']).decode('utf-8').strip()

    # set  new user
    subprocess.check_output(['git', 'config', '--global', 'user.email', email])
    subprocess.check_output(['git', 'config', '--global', 'user.name', user])

    try:
        yield
    finally:
        # restore user
        subprocess.check_output(['git', 'config', '--global', 'user.email', current_user_email])
        subprocess.check_output(['git', 'config', '--global', 'user.name', current_user_name])


def bot_github_user_ctx():
    yield from github_user_ctx('emscripten-forge-bot', 'emscripten-forge-bot@users.noreply.github.com')

@contextmanager
def current_user_ctx():
    yield

def get_current_branch_name():
    return subprocess.check_output(['git', 'rev-parse', '--abbrev-ref', 'HEAD']).decode('utf-8').strip()


@contextmanager
def git_branch_ctx(new_branch_name,  auto_delete=True):

    old_branch_name = get_current_branch_name()

    
    subprocess.check_output(['git', 'checkout', '-b', new_branch_name])


    try:
        yield
    finally:
        subprocess.check_output(['git', 'checkout', old_branch_name, "--force"])
        if auto_delete:
            subprocess.check_output(['git', 'branch', '-D', new_branch_name])


def automerge_is_enabled(pr):
    """Check if automerge is enabled for a specific PR."""
    labels = json.loads(subprocess.check_output(['gh', 'pr', 'view', str(pr), '--json', 'labels']).decode('utf-8'))['labels']

    return 'Automerge' in [label['name'] for label in labels]


