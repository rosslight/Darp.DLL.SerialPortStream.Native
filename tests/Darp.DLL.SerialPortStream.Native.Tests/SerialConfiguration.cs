namespace RJCP.IO.Ports;

// The upstream fixture reads these values through a test-infrastructure project
// that is not part of the SerialPortStream repository. The constructor tests do
// not open the port, so an intentionally nonexistent device is sufficient.
public static class SerialConfiguration
{
    public static string SourcePort => "/dev/ttyUSBX1";
}

