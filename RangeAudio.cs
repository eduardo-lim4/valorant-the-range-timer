using System;
using System.IO;
using System.Text;

public static class RangeAudio
{
    private const int MaxFileBytes = 10 * 1024 * 1024;

    public static byte[] LoadWave(string path)
    {
        FileInfo file = new FileInfo(path);
        if (!file.Exists || file.Length > MaxFileBytes)
            throw new InvalidDataException("O arquivo nao existe ou ultrapassa 10 MB.");
        byte[] bytes = File.ReadAllBytes(path);
        FindSamples(bytes);
        return bytes;
    }

    public static byte[] DefaultWave()
    {
        const int sampleRate = 24000;
        const int sampleCount = sampleRate * 3 / 4;
        using (MemoryStream stream = new MemoryStream())
        using (BinaryWriter writer = new BinaryWriter(stream))
        {
            writer.Write(Encoding.ASCII.GetBytes("RIFF"));
            writer.Write(36 + sampleCount * 2);
            writer.Write(Encoding.ASCII.GetBytes("WAVEfmt "));
            writer.Write(16);
            writer.Write((short)1);
            writer.Write((short)1);
            writer.Write(sampleRate);
            writer.Write(sampleRate * 2);
            writer.Write((short)2);
            writer.Write((short)16);
            writer.Write(Encoding.ASCII.GetBytes("data"));
            writer.Write(sampleCount * 2);
            for (int index = 0; index < sampleCount; index++)
            {
                double time = (double)index / sampleRate;
                bool sounding = time < 0.27 || (time >= 0.37 && time < 0.72);
                double segmentTime = time < 0.27 ? time : time - 0.37;
                double segmentLength = time < 0.27 ? 0.27 : 0.35;
                double envelope = sounding ? Math.Min(1, Math.Min(segmentTime / 0.015, (segmentLength - segmentTime) / 0.015)) : 0;
                writer.Write((short)(Math.Sin(2 * Math.PI * 880 * time) * 18000 * envelope));
            }
            return stream.ToArray();
        }
    }

    public static byte[] AtVolume(byte[] source, int volume)
    {
        if (volume < 0 || volume > 100)
            throw new ArgumentOutOfRangeException("volume");
        int[] samples = FindSamples(source);
        byte[] result = (byte[])source.Clone();
        int end = samples[0] + samples[1];
        for (int position = samples[0]; position < end; position += 2)
        {
            short sample = (short)(result[position] | (result[position + 1] << 8));
            short scaled = (short)(sample * volume / 100);
            result[position] = (byte)(scaled & 255);
            result[position + 1] = (byte)((scaled >> 8) & 255);
        }
        return result;
    }

    private static int[] FindSamples(byte[] bytes)
    {
        if (bytes == null || bytes.Length < 44 || bytes.Length > MaxFileBytes ||
            Encoding.ASCII.GetString(bytes, 0, 4) != "RIFF" || Encoding.ASCII.GetString(bytes, 8, 4) != "WAVE")
            throw new InvalidDataException("O arquivo nao e um WAV valido.");
        uint riffSize = BitConverter.ToUInt32(bytes, 4);
        if (riffSize < 36 || (long)riffSize + 8 > bytes.Length)
            throw new InvalidDataException("O arquivo WAV esta incompleto.");
        int limit = (int)riffSize + 8;
        int position = 12;
        int sampleRate = 0;
        int blockAlign = 0;
        int dataOffset = -1;
        int dataSize = 0;
        while (position + 8 <= limit)
        {
            string id = Encoding.ASCII.GetString(bytes, position, 4);
            uint size = BitConverter.ToUInt32(bytes, position + 4);
            long next = (long)position + 8 + size + (size & 1);
            if (next > limit)
                throw new InvalidDataException("O arquivo WAV esta incompleto.");
            int offset = position + 8;
            if (id == "fmt ")
            {
                if (size < 16)
                    throw new InvalidDataException("O formato do WAV e invalido.");
                int format = BitConverter.ToUInt16(bytes, offset);
                int channels = BitConverter.ToUInt16(bytes, offset + 2);
                sampleRate = BitConverter.ToInt32(bytes, offset + 4);
                int byteRate = BitConverter.ToInt32(bytes, offset + 8);
                blockAlign = BitConverter.ToUInt16(bytes, offset + 12);
                int bits = BitConverter.ToUInt16(bytes, offset + 14);
                if (format != 1 || (channels != 1 && channels != 2) || bits != 16 ||
                    sampleRate < 8000 || sampleRate > 192000 || blockAlign != channels * 2 || byteRate != sampleRate * blockAlign)
                    throw new InvalidDataException("Use WAV PCM de 16 bits, mono ou stereo, entre 8 e 192 kHz.");
            }
            else if (id == "data")
            {
                if (dataOffset >= 0)
                    throw new InvalidDataException("O WAV deve conter apenas um bloco de audio.");
                dataOffset = offset;
                dataSize = (int)size;
            }
            position = (int)next;
        }
        if (sampleRate == 0 || dataOffset < 0 || dataSize == 0 || dataSize % blockAlign != 0 ||
            (long)dataSize > (long)sampleRate * blockAlign * 30)
            throw new InvalidDataException("Use WAV PCM de 16 bits, mono ou stereo, com ate 30 segundos.");
        return new[] { dataOffset, dataSize };
    }
}
