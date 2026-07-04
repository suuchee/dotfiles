#!/usr/bin/env bash
exec env HOOK_FORMAT=claude "$HOME/.agents/hooks/no-gpg-sign-guard.sh"
