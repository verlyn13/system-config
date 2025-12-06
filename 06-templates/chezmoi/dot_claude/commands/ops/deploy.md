---
description: Deployment workflow with pre/post checks
argument-hint: environment (staging/production)
---

# Autonomous Deployment

Deploy to: $ARGUMENTS

## Pre-Deployment Checklist
1. **Tests**: Ensure all tests pass
2. **Build**: Verify clean build
3. **Environment**: Check environment variables
4. **Dependencies**: Check for outdated/vulnerable packages
5. **Secrets**: Verify secrets are in gopass/environment (not committed)
6. **Database**: Check for pending migrations

## Deployment Steps
1. **Tag release**: Create git tag with version
2. **Build artifacts**: Generate production build
3. **Pre-flight checks**: Run health checks
4. **Deploy**: Execute deployment
5. **Smoke tests**: Verify critical paths work
6. **Monitor**: Check logs and metrics

## Post-Deployment
1. **Verify**: Check application health
2. **Rollback plan**: Document rollback steps if needed
3. **Notify**: Update team/stakeholders
4. **Document**: Record deployment in changelog

## Rollback Procedure
If issues detected:
1. Execute rollback immediately
2. Document issue
3. Investigate root cause
4. Fix and redeploy

Be cautious with production deployments.
