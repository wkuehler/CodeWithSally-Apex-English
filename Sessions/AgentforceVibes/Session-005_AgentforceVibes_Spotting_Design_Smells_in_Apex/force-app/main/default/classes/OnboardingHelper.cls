public class OnboardingHelper {

    public static Boolean isValidEmail(String email) {
        if (String.isBlank(email)) {
            return false;
        }
        Pattern emailPattern = Pattern.compile('^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$');
        return emailPattern.matcher(email).matches();
    }

    public static String formatPhoneNumber(String phone) {
        if (String.isBlank(phone)) {
            return null;
        }
        String digitsOnly = phone.replaceAll('[^0-9]', '');
        if (digitsOnly.length() == 10) {
            return digitsOnly.substring(0,3) + '-' +
                   digitsOnly.substring(3,6) + '-' +
                   digitsOnly.substring(6);
        }
        return phone;
    }

    public static String determineOnboardingPriority(Decimal annualRevenue) {
        if (annualRevenue == null) {
            return 'Normal';
        }
        if (annualRevenue > 1000000) {
            return 'Urgent';
        }
        if (annualRevenue > 100000) {
            return 'High';
        }
        return 'Normal';
    }
}
