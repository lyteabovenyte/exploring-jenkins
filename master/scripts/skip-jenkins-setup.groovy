#!groovy

import jenkins.model.*
import hudson.util.*;
import jenkins.install.*;

def isntance = Jenkins.getInstance()

isntance.setInstance(InstallState.INITIAL_SETUP_COMPLETED)