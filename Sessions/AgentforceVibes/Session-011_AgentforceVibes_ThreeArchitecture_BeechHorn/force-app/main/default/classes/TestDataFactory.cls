@IsTest
public class TestDataFactory {

    public static User createStandardUser(String email) {
        Profile p = [
            SELECT Id
            FROM Profile
            WHERE Name = 'Standard User'
            LIMIT 1
        ];
        User u = new User(
            FirstName = 'Test',
            LastName = email.split('@')[0],
            Email = email,
            Username = email + '.' + System.currentTimeMillis(),
            Alias = email.left(8),
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id
        );
        insert u;
        return u;
    }

    public static Trailblazer_Profile__c createProfile() {
        String uniqueToken = String.valueOf(Math.abs(Crypto.getRandomInteger()));
        Trailblazer_Profile__c profile = new Trailblazer_Profile__c(
            Trailhead_Username__c = 'test.user.' + uniqueToken,
            Trailhead_Id__c = '005' + uniqueToken
        );
        insert profile;
        return profile;
    }

    public static Trailblazer_Profile__c createProfileWithCounts(
        Integer badges,
        Integer certs,
        Integer streakDays
    ) {
        Trailblazer_Profile__c profile = createProfile();
        profile.Total_Badges__c = badges;
        profile.Total_Certifications__c = certs;
        profile.Current_Streak__c = streakDays;
        update profile;
        return profile;
    }

    public static Badge__c createBadge(
        Id profileId,
        Date earnedDate,
        String typeValue
    ) {
        Badge__c b = new Badge__c();
        b.Trailblazer_Profile__c = profileId;
        b.Trailhead_Badge_Id__c = 'badge-' + String.valueOf(Math.abs(Crypto.getRandomInteger()));
        b.Badge_Title__c = 'Test Badge';
        b.Badge_Type__c = typeValue;
        b.Earned_Date__c = earnedDate;
        b.Points_Earned__c = 100;
        insert b;
        return b;
    }

    public static Certification__c createCertification(
        Id profileId,
        Date earnedDate
    ) {
        Certification__c c = new Certification__c();
        c.Trailblazer_Profile__c = profileId;
        c.Cert_Id__c = 'cert-' + String.valueOf(Math.abs(Crypto.getRandomInteger()));
        c.Cert_Name__c = 'Test Cert';
        c.Status__c = 'Active';
        c.Date_Earned__c = earnedDate;
        c.Date_Expires__c = earnedDate.addYears(1);
        insert c;
        return c;
    }

    public static XP_Transaction__c createXPTransaction(
        Id profileId,
        Integer amount
    ) {
        XP_Transaction__c t = new XP_Transaction__c();
        t.Trailblazer_Profile__c = profileId;
        t.Action_Type__c = 'Test';
        t.XP_Amount__c = amount;
        t.Transaction_Date__c = System.now();
        insert t;
        return t;
    }

    public static Streak_Freeze__c createStreakFreeze(
        Id profileId,
        Date usedDate
    ) {
        Streak_Freeze__c f = new Streak_Freeze__c();
        f.Trailblazer_Profile__c = profileId;
        f.Used_Date__c = usedDate;
        insert f;
        return f;
    }

    public static Study_Group__c createStudyGroup(
        Integer maxMembers
    ) {
        Study_Group__c g = new Study_Group__c();
        g.Group_Name__c = 'Test Group';
        g.Goal__c = 'Test Goal';
        g.Start_Date__c = Date.today();
        g.End_Date__c = Date.today().addMonths(1);
        g.Max_Members__c = maxMembers;
        insert g;
        return g;
    }

    public static Study_Group_Member__c createStudyGroupMember(
        Id groupId,
        Id profileId,
        String roleValue
    ) {
        Study_Group_Member__c m = new Study_Group_Member__c();
        m.Study_Group__c = groupId;
        m.Trailblazer_Profile__c = profileId;
        m.Role__c = roleValue;
        m.Joined_Date__c = Date.today();
        insert m;
        return m;
    }

    public static List<TrailheadApiService.TrailheadBadge> sampleBadges() {
        List<TrailheadApiService.TrailheadBadge> listResult =
            new List<TrailheadApiService.TrailheadBadge>();
        TrailheadApiService.TrailheadBadge b = new TrailheadApiService.TrailheadBadge();
        b.trailheadBadgeId = 'badge-1';
        b.title = 'Sample Module';
        b.type = 'MODULE';
        b.points = 100;
        b.earnedDate = Date.today();
        b.description = 'Sample badge';
        b.iconUrl = 'https://example.com/icon.png';
        b.trailheadUrl = 'https://trailhead.salesforce.com/sample';
        listResult.add(b);
        return listResult;
    }

    public static List<TrailheadApiService.TrailheadCertification> sampleCerts() {
        List<TrailheadApiService.TrailheadCertification> listResult =
            new List<TrailheadApiService.TrailheadCertification>();
        TrailheadApiService.TrailheadCertification c = new TrailheadApiService.TrailheadCertification();
        c.certId = 'cert-1';
        c.name = 'Sample Cert';
        c.status = 'Active';
        c.earnedDate = Date.today();
        c.expiryDate = Date.today().addYears(1);
        listResult.add(c);
        return listResult;
    }
}

