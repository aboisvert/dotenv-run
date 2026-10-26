# dotenv-run

A Nim port of [dotenv-cli](https://github.com/entropitor/dotenv-cli): load `.env` files into the environment, then run a command.

## Installing

```bash
nimble install dotenvrun
```

Or build from source:

```bash
nimble build
```

The executable is named `dotenv-run`.

## Usage

```bash
dotenv-run -- <command with arguments>
```

Loads variables from `.env` in the current working directory, then runs the command.

```bash
dotenv-run <command>
```

### Custom .env files

```bash
dotenv-run -e .env2 -- <command with arguments>
```

Multiple files (first file wins for each variable unless `-o` is set):

```bash
dotenv-run -e .env3 -e .env4 -- <command with arguments>
```

### Cascading env variables

```bash
dotenv-run -c              # loads .env and .env.local
dotenv-run -c test         # loads .env, .env.local, .env.test, .env.test.local
```

Cannot be combined with `-o`.

### Setting variables from the command line

```bash
dotenv-run -v VARIABLE=somevalue -- <command with arguments>
```

### Check env variable

```bash
dotenv-run -p NODE_ENV
```

### Override

```bash
dotenv-run -e .env.test -o -- jest
```

### Variable expansion

Values in `.env` files support `$VAR` and `${VAR}` expansion (dotenv-expand semantics). Pass `--no-expand` to disable.

### Debugging

```bash
dotenv-run --debug
```

## License

MIT
