---
allowed-tools: Bash(git filter-branch:*), Bash(git rev-parse:*), Bash(FILTER_BRANCH_SQUELCH_WARNING:*), mcp__git__git_set_working_dir, mcp__git__git_log, mcp__git__git_show, mcp__git__git_diff, mcp__git__git_branch
description: Rewrite git commit message
---

# Rewrite Git Commit Message Command

This command will analyze the specified commit, create an improved commit message following Conventional Commits specification, and then actually rewrite the commit message in git history using git filter-branch.

## Overview

This command analyzes a commit, creates an improved message following Conventional Commits specification, and rewrites the commit message in git history. See "Execution Instructions" below for detailed steps.

The message should not be too long and have maximum 10 bullet points.

Here the specification for "conventional commits":

Conventional Commits 1.0.0

Summary

The Conventional Commits specification is a lightweight convention on top of commit messages.
It provides an easy set of rules for creating an explicit commit history;
which makes it easier to write automated tools on top of.
This convention dovetails with [SemVer](http://semver.org),
by describing the features, fixes, and breaking changes made in commit messages.

The commit message should be structured as follows:

---

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```
---

<br />
The commit contains the following structural elements, to communicate intent to the
consumers of your library:

1. **fix:** a commit of the _type_ `fix` patches a bug in your codebase (this correlates with [`PATCH`](http://semver.org/#summary) in Semantic Versioning).
1. **feat:** a commit of the _type_ `feat` introduces a new feature to the codebase (this correlates with [`MINOR`](http://semver.org/#summary) in Semantic Versioning).
1. **BREAKING CHANGE:** a commit that has a footer `BREAKING CHANGE:`, or appends a ! after the type/scope, introduces a breaking API change (correlating with [`MAJOR`](http://semver.org/#summary) in Semantic Versioning).
   A BREAKING CHANGE can be part of commits of any _type_.
1. _types_ other than `fix:` and `feat:` are allowed, for example [@commitlint/config-conventional](https://github.com/conventional-changelog/commitlint/tree/master/%40commitlint/config-conventional) (based on the [Angular convention](https://github.com/angular/angular/blob/22b96b9/CONTRIBUTING.md#-commit-message-guidelines)) recommends `build:`, `chore:`,
   `ci:`, `docs:`, `style:`, `refactor:`, `perf:`, `test:`, and others.
1. _footers_ other than `BREAKING CHANGE: <description>` may be provided and follow a convention similar to
   [git trailer format](https://git-scm.com/docs/git-interpret-trailers).

Additional types are not mandated by the Conventional Commits specification, and have no implicit effect in Semantic Versioning (unless they include a BREAKING CHANGE).
<br /><br />
A scope may be provided to a commit's type, to provide additional contextual information and is contained within parenthesis, e.g., `feat(parser): add ability to parse arrays`.

Examples

Commit message with description and breaking change footer
```
MLE-999: feat: allow provided config object to extend other configs

BREAKING CHANGE: `extends` key in config file is now used for extending other config files
```

Commit message with ! to draw attention to breaking change
```
MLE-999: feat!: send an email to the customer when a product is shipped
```

Commit message with scope and ! to draw attention to breaking change
```
MLE-999: feat(api)!: send an email to the customer when a product is shipped
```

Commit message with both ! and BREAKING CHANGE footer
```
MLE-999: chore!: drop support for Node 6

BREAKING CHANGE: use JavaScript features not available in Node 6.
```

Commit message with no body
```
MLE-999: docs: correct spelling of CHANGELOG
```

Commit message with scope
```
MLE-999: feat(lang): add Polish language
```

Commit message with multi-paragraph body and multiple footers
```
MLE-999: fix: prevent racing of requests

Introduce a request id and a reference to latest request. Dismiss
incoming responses other than from latest request.

Remove timeouts which were used to mitigate the racing issue but are
obsolete now.

Reviewed-by: Z
Refs: #123
```

Specification

The key words “MUST”, “MUST NOT”, “REQUIRED”, “SHALL”, “SHALL NOT”, “SHOULD”, “SHOULD NOT”, “RECOMMENDED”, “MAY”, and “OPTIONAL” in this document are to be interpreted as described in [RFC 2119](https://www.ietf.org/rfc/rfc2119.txt).

1. Commits MUST be prefixed with the jira ticket number that looks something like this MLE-999 or TE-222.
1. Commits MUST be prefixed with a type, which consists of a noun, `feat`, `fix`, etc., followed
   by the OPTIONAL scope, OPTIONAL !, and REQUIRED terminal colon and space.
1. The type `feat` MUST be used when a commit adds a new feature to your application or library.
1. The type `fix` MUST be used when a commit represents a bug fix for your application.
1. A scope MAY be provided after a type. A scope MUST consist of a noun describing a
   section of the codebase surrounded by parenthesis, e.g., `fix(parser):`
1. A description MUST immediately follow the colon and space after the type/scope prefix.
   The description is a short summary of the code changes, e.g., _fix: array parsing issue when multiple spaces were contained in string_.
1. A longer commit body MAY be provided after the short description, providing additional contextual information about the code changes. The body MUST begin one blank line after the description.
1. A commit body is free-form and MAY consist of any number of newline separated paragraphs.
1. One or more footers MAY be provided one blank line after the body. Each footer MUST consist of
   a word token, followed by either a `:<space>` or `<space>#` separator, followed by a string value (this is inspired by the
   [git trailer convention](https://git-scm.com/docs/git-interpret-trailers)).
1. A footer's token MUST use `-` in place of whitespace characters, e.g., `Acked-by` (this helps differentiate
   the footer section from a multi-paragraph body). An exception is made for `BREAKING CHANGE`, which MAY also be used as a token.
1. A footer's value MAY contain spaces and newlines, and parsing MUST terminate when the next valid footer
   token/separator pair is observed.
1. Breaking changes MUST be indicated in the type/scope prefix of a commit, or as an entry in the
   footer.
1. If included as a footer, a breaking change MUST consist of the uppercase text BREAKING CHANGE, followed by a colon, space, and description, e.g.,
   _BREAKING CHANGE: environment variables now take precedence over config files_.
1. If included in the type/scope prefix, breaking changes MUST be indicated by a
   ! immediately before the `:`. If ! is used, `BREAKING CHANGE:` MAY be omitted from the footer section,
   and the commit description SHALL be used to describe the breaking change.
1. Types other than `feat` and `fix` MAY be used in your commit messages, e.g., _docs: update ref docs._
1. The units of information that make up Conventional Commits MUST NOT be treated as case sensitive by implementors, with the exception of BREAKING CHANGE which MUST be uppercase.
1. BREAKING-CHANGE MUST be synonymous with BREAKING CHANGE, when used as a token in a footer.

Why Use Conventional Commits

* Automatically generating CHANGELOGs.
* Automatically determining a semantic version bump (based on the types of commits landed).
* Communicating the nature of changes to teammates, the public, and other stakeholders.
* Triggering build and publish processes.
* Making it easier for people to contribute to your projects, by allowing them to explore
  a more structured commit history.

FAQ

How should I deal with commit messages in the initial development phase?

We recommend that you proceed as if you've already released the product. Typically *somebody*, even if it's your fellow software developers, is using your software. They'll want to know what's fixed, what breaks etc.

Are the types in the commit title uppercase or lowercase?

Any casing may be used, but it's best to be consistent.

What do I do if the commit conforms to more than one of the commit types?

Go back and make multiple commits whenever possible. Part of the benefit of Conventional Commits is its ability to drive us to make more organized commits and PRs.

Doesn’t this discourage rapid development and fast iteration?

It discourages moving fast in a disorganized way. It helps you be able to move fast long term across multiple projects with varied contributors.

Might Conventional Commits lead developers to limit the type of commits they make because they'll be thinking in the types provided?

Conventional Commits encourages us to make more of certain types of commits such as fixes. Other than that, the flexibility of Conventional Commits allows your team to come up with their own types and change those types over time.

How does this relate to SemVer?

`fix` type commits should be translated to `PATCH` releases. `feat` type commits should be translated to `MINOR` releases. Commits with `BREAKING CHANGE` in the commits, regardless of type, should be translated to `MAJOR` releases.

How should I version my extensions to the Conventional Commits Specification, e.g. `@jameswomack/conventional-commit-spec`?

We recommend using SemVer to release your own extensions to this specification (and
encourage you to make these extensions!)

What do I do if I accidentally use the wrong commit type?

When you used a type that's of the spec but not the correct type, e.g. `fix` instead of `feat`

Prior to merging or releasing the mistake, we recommend using `git rebase -i` to edit the commit history. After release, the cleanup will be different according to what tools and processes you use.

When you used a type *not* of the spec, e.g. `feet` instead of `feat`

In a worst case scenario, it's not the end of the world if a commit lands that does not meet the Conventional Commits specification. It simply means that commit will be missed by tools that are based on the spec.

Do all my contributors need to use the Conventional Commits specification?

No! If you use a squash based workflow on Git lead maintainers can clean up the commit messages as they're merged—adding no workload to casual committers.
A common workflow for this is to have your git system automatically squash commits from a pull request and present a form for the lead maintainer to enter the proper git commit message for the merge.

How does Conventional Commits handle revert commits?

Reverting code can be complicated: are you reverting multiple commits? if you revert a feature, should the next release instead be a patch?

Conventional Commits does not make an explicit effort to define revert behavior. Instead we leave it to tooling
authors to use the flexibility of _types_ and _footers_ to develop their logic for handling reverts.

One recommendation is to use the `revert` type, and a footer that references the commit SHAs that are being reverted:

```
revert: let us never again speak of the noodle incident

Refs: 676104e, a215868
```

## Execution Instructions

After analyzing the commit and creating an improved message following the specification above, you MUST follow these steps:

### 1. Initialize Repository Context (REQUIRED FIRST)

Use **`mcp__git__git_set_working_dir`**:
- Pass `path: "."`
- Pass `includeMetadata: true`
- This validates the git repository, sets the session working directory, and returns repository metadata

### 2. Analyze the Commit

Use MCP git tools to understand the commit (path parameter omitted - uses session working directory):

- **`mcp__git__git_show`** with the commit reference to examine:
  - The commit metadata (author, date, hash)
  - The full diff of changes
  - The current commit message (to improve upon)

### 3. Understand Context

- **`mcp__git__git_log`**: Review recent commits (path parameter omitted):
  - Pass `maxCount: 10` to limit results
  - Understand commit message style and patterns
  - Ensure consistency with repository conventions
  - See the commit history context

### 4. Get Target Commit Hash

Use `Bash` tool with `git rev-parse`:

```bash
git rev-parse <commit-ref>
```

This resolves the reference (HEAD, HEAD~1, etc.) to the actual commit hash needed for filter-branch.

### 5. Generate Improved Message

Create an improved commit message that:
- Follows the Conventional Commits specification exactly
- Includes the Jira ticket prefix (MLE-999 or TE-222)
- Uses appropriate type (feat, fix, docs, etc.)
- Provides concise description in imperative mood
- Includes body with max 10 bullet points if needed
- Maintains consistency with repository style

### 6. Determine Commit Range

Calculate the appropriate range for filter-branch based on the commit reference:

**Examples of commit references and ranges:**
- `HEAD`: Most recent commit → Range: `HEAD~1..HEAD`
- `HEAD~1`: One commit back → Range: `HEAD~2..HEAD~1`
- `HEAD~2`: Two commits back → Range: `HEAD~3..HEAD~2`
- `<commit-hash>`: Specific commit → Range determined by position from HEAD

### 7. Rewrite the Commit Message

Use `Bash` tool with `git filter-branch`:

```bash
FILTER_BRANCH_SQUELCH_WARNING=1 git filter-branch -f --msg-filter 'if [ "$GIT_COMMIT" = "<TARGET_COMMIT_HASH>" ]; then echo "<NEW_MESSAGE>"; else cat; fi' <RANGE>
```

**Important Notes:**
- Always use `FILTER_BRANCH_SQUELCH_WARNING=1` to suppress warnings
- Use `-f` flag to force overwrite refs
- The range should start one commit before the target and end at HEAD
- Multi-line commit messages require proper shell escaping (use `echo -e` or heredoc)

**For multi-line messages, use this pattern:**
```bash
FILTER_BRANCH_SQUELCH_WARNING=1 git filter-branch -f --msg-filter 'if [ "$GIT_COMMIT" = "<TARGET_COMMIT_HASH>" ]; then cat <<EOF
<line 1>
<line 2>
<line 3>
EOF
else cat; fi' <RANGE>
```

### 8. Verify the Change

Use **`mcp__git__git_log`** or **`mcp__git__git_show`** (path parameter omitted) to:
- Confirm the commit message was updated successfully
- Show the new message to verify correctness
- Check that only the intended commit was modified

### 9. Report Results

Show the user:
- The old commit message
- The new commit message
- Confirmation of successful rewrite
- Warning about force-push if already pushed to remote

## Input Format

The commit reference (`$ARGUMENTS`) can be:
- `HEAD` - Most recent commit
- `HEAD~1`, `HEAD~2` - Previous commits
- `<commit-hash>` - Specific commit by hash
- `<branch-name>` - Latest commit on a branch

## Usage Examples

**Example 1: Rewrite most recent commit**
```
/rewrite_commit_message HEAD
```

**Example 2: Rewrite specific commit**
```
/rewrite_commit_message abc1234
```

**Example 3: Rewrite commit from two commits back**
```
/rewrite_commit_message HEAD~2
```

## Important Warnings

⚠️ **This command rewrites git history!**
- If the commit has been pushed to remote, you'll need to force-push
- Force-pushing can affect other developers working on the same branch
- Only use on commits that haven't been shared, or coordinate with your team

Here is the commit reference: $ARGUMENTS
