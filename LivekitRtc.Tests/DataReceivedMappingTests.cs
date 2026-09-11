using System.Runtime.InteropServices;
using Xunit;

namespace LiveKit.Rtc.Tests;

/// <summary>
/// Unit tests that verify a data packet from the FFI reaches <see cref="Room.DataReceived"/>
/// with the encryption type the native side reported for it, without a LiveKit server.
///
/// A receiver that requires encryption refuses a packet reported as
/// <c>EncryptionType.None</c>. A handler that dropped the field, or reported a constant, would
/// have every packet accepted or every packet refused, and only a live room would show it.
/// </summary>
public class DataReceivedMappingTests
{
    private static async Task<DataReceivedEventArgs> ReceiveAsync(
        byte[] payload,
        Proto.EncryptionType encryption
    )
    {
        var ptr = Marshal.AllocHGlobal(payload.Length);
        try
        {
            Marshal.Copy(payload, 0, ptr, payload.Length);
            var packet = new Proto.DataPacketReceived
            {
                Kind = Proto.DataPacketKind.KindReliable,
                ParticipantIdentity = string.Empty,
                User = new Proto.UserPacket
                {
                    // No handle: the buffer is this test's, not the native side's to free.
                    Data = new Proto.OwnedBuffer
                    {
                        Data = new Proto.BufferInfo
                        {
                            DataPtr = (ulong)ptr.ToInt64(),
                            DataLen = (ulong)payload.Length,
                        },
                    },
                    Topic = "session",
                    EncryptionType = encryption,
                },
            };

            using var room = new Room();
            var received = new TaskCompletionSource<DataReceivedEventArgs>(
                TaskCreationOptions.RunContinuationsAsynchronously
            );
            room.DataReceived += (_, e) => received.TrySetResult(e);

            room.HandleDataPacketReceived(packet);

            return await received.Task.WaitAsync(TimeSpan.FromSeconds(5));
        }
        finally
        {
            Marshal.FreeHGlobal(ptr);
        }
    }

    [Theory]
    [InlineData(Proto.EncryptionType.Gcm)]
    [InlineData(Proto.EncryptionType.Custom)]
    [InlineData(Proto.EncryptionType.None)]
    public async Task A_data_packet_carries_the_encryption_type_the_native_side_reported(
        Proto.EncryptionType encryption
    )
    {
        var received = await ReceiveAsync(new byte[] { 1, 2, 3 }, encryption);

        Assert.Equal(encryption, received.EncryptionType);
        Assert.Equal(new byte[] { 1, 2, 3 }, received.Data);
        Assert.Equal("session", received.Topic);
    }

    [Fact]
    public async Task A_packet_from_a_native_that_does_not_report_the_field_reads_as_unencrypted()
    {
        var ptr = Marshal.AllocHGlobal(1);
        try
        {
            Marshal.WriteByte(ptr, 7);
            var packet = new Proto.DataPacketReceived
            {
                Kind = Proto.DataPacketKind.KindReliable,
                ParticipantIdentity = string.Empty,
                User = new Proto.UserPacket
                {
                    Data = new Proto.OwnedBuffer
                    {
                        Data = new Proto.BufferInfo { DataPtr = (ulong)ptr.ToInt64(), DataLen = 1 },
                    },
                },
            };

            using var room = new Room();
            var received = new TaskCompletionSource<DataReceivedEventArgs>(
                TaskCreationOptions.RunContinuationsAsynchronously
            );
            room.DataReceived += (_, e) => received.TrySetResult(e);

            room.HandleDataPacketReceived(packet);
            var e = await received.Task.WaitAsync(TimeSpan.FromSeconds(5));

            // Refused rather than trusted by a receiver that requires encryption.
            Assert.False(packet.User.HasEncryptionType);
            Assert.Equal(Proto.EncryptionType.None, e.EncryptionType);
        }
        finally
        {
            Marshal.FreeHGlobal(ptr);
        }
    }
}
