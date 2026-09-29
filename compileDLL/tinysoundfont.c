#include <windows.h>

// Visual Studio Export-Makro
#define TSF_API __declspec(dllexport)

// TinySoundFont Implementation aktivieren
#define TSF_IMPLEMENTATION
#include "tsf.h"

// ALLE FUNKTIONEN EXPORTIEREN
TSF_API tsf* dll_tsf_load_filename(const char* filename) { return tsf_load_filename(filename); }
TSF_API tsf* dll_tsf_load_memory(const void* buffer, int size) { return tsf_load_memory(buffer, size); }
TSF_API tsf* dll_tsf_copy(tsf* f) { return tsf_copy(f); }
TSF_API void dll_tsf_close(tsf* f) { tsf_close(f); }
TSF_API void dll_tsf_reset(tsf* f) { tsf_reset(f); }
TSF_API int dll_tsf_get_presetindex(const tsf* f, int bank, int preset_number) { return tsf_get_presetindex(f, bank, preset_number); }
TSF_API int dll_tsf_get_presetcount(const tsf* f) { return tsf_get_presetcount(f); }
TSF_API const char* dll_tsf_get_presetname(const tsf* f, int preset_index) { return tsf_get_presetname(f, preset_index); }
TSF_API const char* dll_tsf_bank_get_presetname(const tsf* f, int bank, int preset_number) { return tsf_bank_get_presetname(f, bank, preset_number); }
TSF_API void dll_tsf_set_output(tsf* f, int outputmode, int samplerate, float global_gain_db) { tsf_set_output(f, (enum TSFOutputMode)outputmode, samplerate, global_gain_db); }
TSF_API void dll_tsf_set_volume(tsf* f, float global_gain) { tsf_set_volume(f, global_gain); }
TSF_API int dll_tsf_set_max_voices(tsf* f, int max_voices) { return tsf_set_max_voices(f, max_voices); }
TSF_API int dll_tsf_note_on(tsf* f, int preset_index, int key, float vel) { return tsf_note_on(f, preset_index, key, vel); }
TSF_API int dll_tsf_bank_note_on(tsf* f, int bank, int preset_number, int key, float vel) { return tsf_bank_note_on(f, bank, preset_number, key, vel); }
TSF_API void dll_tsf_note_off(tsf* f, int preset_index, int key) { tsf_note_off(f, preset_index, key); }
TSF_API int dll_tsf_bank_note_off(tsf* f, int bank, int preset_number, int key) { return tsf_bank_note_off(f, bank, preset_number, key); }
TSF_API void dll_tsf_note_off_all(tsf* f) { tsf_note_off_all(f); }
TSF_API int dll_tsf_active_voice_count(tsf* f) { return tsf_active_voice_count(f); }
TSF_API void dll_tsf_render_short(tsf* f, short* buffer, int samples, int flag_mixing) { tsf_render_short(f, buffer, samples, flag_mixing); }
TSF_API void dll_tsf_render_float(tsf* f, float* buffer, int samples, int flag_mixing) { tsf_render_float(f, buffer, samples, flag_mixing); }
TSF_API int dll_tsf_channel_set_presetindex(tsf* f, int channel, int preset_index) { return tsf_channel_set_presetindex(f, channel, preset_index); }
TSF_API int dll_tsf_channel_set_presetnumber(tsf* f, int channel, int preset_number, int flag_mididrums) { return tsf_channel_set_presetnumber(f, channel, preset_number, flag_mididrums); }
TSF_API int dll_tsf_channel_set_bank(tsf* f, int channel, int bank) { return tsf_channel_set_bank(f, channel, bank); }
TSF_API int dll_tsf_channel_set_bank_preset(tsf* f, int channel, int bank, int preset_number) { return tsf_channel_set_bank_preset(f, channel, bank, preset_number); }
TSF_API int dll_tsf_channel_set_pan(tsf* f, int channel, float pan) { return tsf_channel_set_pan(f, channel, pan); }
TSF_API int dll_tsf_channel_set_volume(tsf* f, int channel, float volume) { return tsf_channel_set_volume(f, channel, volume); }
TSF_API int dll_tsf_channel_set_pitchwheel(tsf* f, int channel, int pitch_wheel) { return tsf_channel_set_pitchwheel(f, channel, pitch_wheel); }
TSF_API int dll_tsf_channel_set_pitchrange(tsf* f, int channel, float pitch_range) { return tsf_channel_set_pitchrange(f, channel, pitch_range); }
TSF_API int dll_tsf_channel_set_tuning(tsf* f, int channel, float tuning) { return tsf_channel_set_tuning(f, channel, tuning); }
TSF_API int dll_tsf_channel_set_sustain(tsf* f, int channel, int flag_sustain) { return tsf_channel_set_sustain(f, channel, flag_sustain); }
TSF_API int dll_tsf_channel_note_on(tsf* f, int channel, int key, float vel) { return tsf_channel_note_on(f, channel, key, vel); }
TSF_API void dll_tsf_channel_note_off(tsf* f, int channel, int key) { tsf_channel_note_off(f, channel, key); }
TSF_API void dll_tsf_channel_note_off_all(tsf* f, int channel) { tsf_channel_note_off_all(f, channel); }
TSF_API void dll_tsf_channel_sounds_off_all(tsf* f, int channel) { tsf_channel_sounds_off_all(f, channel); }
TSF_API int dll_tsf_channel_midi_control(tsf* f, int channel, int controller, int control_value) { return tsf_channel_midi_control(f, channel, controller, control_value); }
TSF_API int dll_tsf_channel_get_preset_index(tsf* f, int channel) { return tsf_channel_get_preset_index(f, channel); }
TSF_API int dll_tsf_channel_get_preset_bank(tsf* f, int channel) { return tsf_channel_get_preset_bank(f, channel); }
TSF_API int dll_tsf_channel_get_preset_number(tsf* f, int channel) { return tsf_channel_get_preset_number(f, channel); }
TSF_API float dll_tsf_channel_get_pan(tsf* f, int channel) { return tsf_channel_get_pan(f, channel); }
TSF_API float dll_tsf_channel_get_volume(tsf* f, int channel) { return tsf_channel_get_volume(f, channel); }
TSF_API int dll_tsf_channel_get_pitchwheel(tsf* f, int channel) { return tsf_channel_get_pitchwheel(f, channel); }
TSF_API float dll_tsf_channel_get_pitchrange(tsf* f, int channel) { return tsf_channel_get_pitchrange(f, channel); }
TSF_API float dll_tsf_channel_get_tuning(tsf* f, int channel) { return tsf_channel_get_tuning(f, channel); }