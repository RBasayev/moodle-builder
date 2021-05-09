# MoodleBuilder

Automatic builder of Moodle packages.

<img src="zpk/imoo.png" alt="Instant Moodle" width=200 height=200 />


## Zend Server ZPK
(this section is temporary - details will be added and it will be moved to README.md in the ZPK itself)

Beginning with this, as this is one that I know well.

Running Docker Compose in the root directory builds the ZPK and puts it into the `result/` directory.

Running Docker Compose in the `test/` directory launches a small Zend Server + PostgreSQL + Moodle. To open Moodle, issue these two commands as root:

```bash
# Docker Compose will install and configure the ZPK for instant.moodle.lcl
echo "127.0.0.1   instant.moodle.lcl" >> /etc/hosts

# Moodle seems to insist on port 80 (maybe configurable, don't care)
ssh -L 80:127.0.0.1:2080 [user@]127.0.0.1
```

Then open http://instant.moodle.lcl in the browser. The admin user is __su__, the password is __imoosupass__ .

The Zend Server UI is at http://127.0.0.1:10081 (password __zend__). Job Queue is configured to run Moodle's cron.php every 10 minutes.

## Automatic Release

The workflow is triggered...

```yaml
on:
  # I want to do this on schedule, but 'push' for now
  push:
    branches:
      - "release_3.10"
      - "release_3.11"
      - "release_4.0"
```

## The Point of This

The point is to practice automatic building, testing, play with GitHub Actions. The ZPK is only the first format, will add at least one more - if time permits and I don't lose interest.
