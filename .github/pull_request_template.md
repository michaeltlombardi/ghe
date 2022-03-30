# PR Summary
<!--
    Summarize your changes and list related issues here. For example:

    This changes fixes problem X in the documentation for Y.
    - Fixes #1234
    - Resolves #1235
-->

## Affected Files

<!--
    Delete the entries in each of the lists below that that this PR does
    not affect. After deleting entries, if a section is empty, delete it
-->

### Foo

- Repository documentation and configuration (.git/.github/.vscode etc.)
- Docs build files (.openpublishing.* and build scripts)
- Docset configuration (docfx.json, mapping, bread, module folder)

### Bar

- Files in docs-conceptual

### Cmdlet reference & about_ topics

<!--
    When changing cmdlet reference or about_ topics, the changes should
    be copied to all relevant versions. Delete the entries for any
    version in this list that this PR does not affect:
-->

- Preview content
- Version 7.2 content
- Version 7.1 content
- Version 7.0 content
- Version 5.1 content

## PR Checklist

<!--
    These items are mandatory. For your PR to be reviewed and merged,
    ensure you have followed these steps. As you complete the steps,
    check each box by replacing the space between the brackets with an
    x or by clicking on the box in the UI after your PR is submitted.
-->

- [ ] I have read the [contributors guide][contrib] and followed the style and process guidelines
- [ ] PR has a meaningful title
- [ ] PR is targeted at the _staging_ branch
- [ ] All relevant versions updated
- [ ] Includes content related to issues and PRs - see [Closing issues using keywords][key].
- [ ] This PR is ready to merge and is not **Work in Progress**. If the PR is work in progress,
  please add the prefix `WIP:` or `[WIP]` to the beginning of the title and remove the prefix when
  the PR is ready.

[contrib]: https://docs.microsoft.com/powershell/scripting/community/contributing/overview
[key]: https://help.github.com/en/articles/closing-issues-using-keywords