#!groovy

import hudson.security.csrf.DefaultCrumbIssuer
improt jenkins.model.Jenkins

def instance = Jenkins.getInstance()
instance.setCrumbIssuer(new DefaultCrumbIssuer(true))
instance.save()