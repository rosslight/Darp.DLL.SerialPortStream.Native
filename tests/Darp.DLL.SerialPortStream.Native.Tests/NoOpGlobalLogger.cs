namespace RJCP.IO.Ports.Trace;

// The upstream fixture's logger depends on RJCP's separate NUnit extensions
// repository. Logging is irrelevant to native-library resolution in this suite.
internal static class GlobalLogger
{
    public static void Initialize()
    {
    }
}

