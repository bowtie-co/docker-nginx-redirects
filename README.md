# docker-nginx-redirects
Generic redirect handler

### Setup

Pull latest docker image

```bash
docker pull bowtie/nginx-redirects
```

Build it yourself (from this repo)

```bash
docker build -t bowtie/nginx-redirects .
```

### Usage

All incoming servernames redirected to a single destination

```bash
docker run -it -p 8080:80 -e SERVER_REDIRECTS=https://google.com bowtie/nginx-redirects
```

- http://localhost:8080 should redirect to https://google.com

Different destination based on incoming servername

```bash
docker run -it -p 8080:80 -e SERVER_REDIRECTS=https://google.com%localhost,https://github.com%127.0.0.1 bowtie/nginx-redirects
```
- http://localhost:8080 should redirect to https://google.com
- http://127.0.0.1:8080 should redirect to https://github.com

Specify redirect code (defaults to 302, temporary)

```bash
docker run -it -p 8080:80 -e SERVER_REDIRECTS=https://google.com%localhost%301,https://github.com%127.0.0.1%302 bowtie/nginx-redirects
```

- http://localhost:8080 should 301 (permanent) redirect to https://google.com
- http://127.0.0.1:8080 should 302 (temporary) redirect to https://github.com

### Configuration

Single ENV var expected: `SERVER_REDIRECTS`

A single redirect configuration group looks like
- `DESTINATION%SOURCE%CODE`
  - Config parts are separated by `%`
  - `DESTINATION` *required*
    - Where to redirect requests to
  - `SOURCE` *optional*
    - When to redirect to `DESTINATION`
    - Defaults to `_` (all incoming server names)
    - Supports nginx `server_name` regex patterns
  - `CODE` *optional*
    - Redirect HTTP code to be used (must be `301` or `302`)
    - Defaults to `302` (temporary redirect)

You can specify more than 1 configuration group as comma separated list

```bash
SERVER_REDIRECTS=D1%S1,D2%S2,D3%S3,...
```
