# Security

pmkit is Markdown files and small local scripts. It runs no servers or hosted services and collects no data. The only network access happens when you approve an installer, which then downloads a third-party tool from its official source.

## Reporting a problem

If you find a security issue in the kit, for example a script that writes outside your project, exposes a secret or runs something you did not approve, please report it privately:

- Use GitHub's [private vulnerability reporting](https://github.com/Shanmuga-Raja-Portfolio/Project-Management_template/security/advisories/new) for this repo.
- Include the file, the command you ran and what happened. Please leave out real keys and tokens.

We aim to reply within a week, and ask that you give us a fair chance to fix it before sharing details publicly.

## Third-party tools

Problems inside a tool the kit links to, such as graphify or Strix, belong with that project, so please report them upstream. If a tool card describes a risk wrongly, open an issue here and we will correct the card.

Security testing tools such as Strix may only be used on systems you own or have written permission to test.

For what each tool sends over the network, see [guides/privacy-and-network.md](guides/privacy-and-network.md).
