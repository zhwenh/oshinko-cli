#!/bin/bash
source "$(dirname "${BASH_SOURCE}")/../../hack/lib/init.sh"
trap os::test::junit::reconcile_output EXIT

os::test::junit::declare_suite_start "cmd/deleteeph"

# No clusters notice
os::cmd::try_until_text "_output/oshinko get" "There are no clusters in any projects. You can create a cluster with the 'create' command."

# Create clusters so we can look at them
os::cmd::expect_success "_output/oshinko create abc --workers=2"

# name required
os::cmd::expect_failure "_output/oshinko delete_eph"

# delete happens
os::cmd::expect_success "_output/oshinko create bob"
os::cmd::expect_success "_output/oshinko delete_eph bob"
os::cmd::expect_failure "_output/oshinko get bob"

# ephemeral flags
os::cmd::expect_failure_and_text "_output/oshinko delete_eph bob --app=sam-1" "Both --app and --app-status must be set"
os::cmd::expect_failure_and_text "_output/oshinko delete_eph bob --app-status=completed" "Both --app and --app-status must be set"
os::cmd::expect_failure_and_text "_output/oshinko delete_eph bob --app=sam-1 --app-status=wrong" "INVALID app-status value, only completed|terminated allowed"

os::cmd::expect_success "_output/oshinko create fodder"
os::cmd::expect_success_and_text "_output/oshinko create_eph -e cluster --app=fodder-m-1" 'ephemeral cluster "cluster" created'
os::cmd::expect_failure_and_text "_output/oshinko delete_eph cluster --app=someother --app-status=terminated" "cluster is not linked to app"

# replica count won't work for hack/test-cmd, so only do this test when we're started from run.sh
if [ "${USING_OPENSHIFT_INSTANCE:-false}" == true ]; then
    os::cmd::try_until_text "oc get rc fodder-m-1 --template='{{index .status \"replicas\"}}'" "1"
    os::cmd::expect_failure_and_text "_output/oshinko delete_eph cluster --app=fodder-m-1 --app-status=terminated" "driver replica count > 0 \(or > 1 for completed app\)"
fi

os::cmd::expect_success "_output/oshinko delete_eph cluster --app=fodder-m-1 --app-status=completed"

os::test::junit::declare_suite_end
