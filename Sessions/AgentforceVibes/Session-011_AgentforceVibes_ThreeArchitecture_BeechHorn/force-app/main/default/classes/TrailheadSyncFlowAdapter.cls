public with sharing class TrailheadSyncFlowAdapter {

    public class Input {
        @InvocableVariable
        public Id profileId;
    }

    public class Output {
        @InvocableVariable
        public String message;
    }

    @InvocableMethod(
        label='Sync Trailblazer Profiles (Flow Adapter)'
        description='Queues a Trailhead sync for one or more Trailblazer profiles and returns a status message per record.'
    )
    public static List<Output> run(List<Input> inputs) {
        List<Output> results = new List<Output>();
        if (inputs == null) {
            return results;
        }

        for (Input inParam : inputs) {
            Output out = new Output();
            results.add(out);

            Id profileId = inParam != null ? inParam.profileId : null;
            if (profileId == null) {
                out.message = 'No profileId supplied.';
                continue;
            }

            try {
                // Delegate to existing service method used by other entry points.
                out.message = TrailheadSyncService.syncNow(profileId);
            } catch (Exception e) {
                // Surface a friendly message to Flow while allowing underlying
                // logging/integration records to capture the detailed error.
                out.message = 'Trailhead sync failed: ' + e.getMessage();
            }
        }

        return results;
    }
}

