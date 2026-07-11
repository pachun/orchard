#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <unistd.h>
#include <sys/mman.h>
#include <stdint.h>
#include <wayland-client.h>
#include "wlr-gamma-control-client-protocol.h"

static struct zwlr_gamma_control_manager_v1 *gamma_manager = NULL;

struct output {
    struct wl_output *wl_output;
    struct zwlr_gamma_control_v1 *gamma_control;
    struct output *next;
};
static struct output *outputs = NULL;

static double gain_r = 1.0, gain_g = 1.0, gain_b = 1.0;
static double exp_r = 1.0, exp_g = 1.0, exp_b = 1.0;

static void fill_ramp(uint16_t *table, uint32_t size, double gain, double e) {
    for (uint32_t i = 0; i < size; i++) {
        double norm = (size <= 1) ? 0.0 : (double)i / (double)(size - 1);
        double val = pow(norm, e) * gain;
        if (val < 0) val = 0;
        if (val > 1) val = 1;
        table[i] = (uint16_t)(val * 65535.0 + 0.5);
    }
}

static void gamma_size(void *data, struct zwlr_gamma_control_v1 *ctrl, uint32_t size) {
    size_t total = (size_t)size * 3 * sizeof(uint16_t);
    int fd = memfd_create("gamma", 0);
    if (fd < 0 || ftruncate(fd, total) < 0) { fprintf(stderr, "fd fail\n"); return; }
    uint16_t *d = mmap(NULL, total, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
    if (d == MAP_FAILED) { fprintf(stderr, "mmap fail\n"); close(fd); return; }
    fill_ramp(d, size, gain_r, exp_r);
    fill_ramp(d + size, size, gain_g, exp_g);
    fill_ramp(d + size * 2, size, gain_b, exp_b);
    munmap(d, total);
    zwlr_gamma_control_v1_set_gamma(ctrl, fd);
    close(fd);
}
static void gamma_failed(void *data, struct zwlr_gamma_control_v1 *ctrl) {
    fprintf(stderr, "gamma control failed (another gamma client holding the output?)\n");
}
static const struct zwlr_gamma_control_v1_listener gamma_listener = {
    .gamma_size = gamma_size, .failed = gamma_failed,
};

static void reg_global(void *data, struct wl_registry *r, uint32_t name, const char *iface, uint32_t ver) {
    if (!strcmp(iface, wl_output_interface.name)) {
        struct output *o = calloc(1, sizeof(*o));
        o->wl_output = wl_registry_bind(r, name, &wl_output_interface, 1);
        o->next = outputs; outputs = o;
    } else if (!strcmp(iface, zwlr_gamma_control_manager_v1_interface.name)) {
        gamma_manager = wl_registry_bind(r, name, &zwlr_gamma_control_manager_v1_interface, 1);
    }
}
static void reg_remove(void *data, struct wl_registry *r, uint32_t name) {}
static const struct wl_registry_listener reg_listener = { .global = reg_global, .global_remove = reg_remove };

int main(int argc, char **argv) {
    if (argc >= 4) { gain_r = atof(argv[1]); gain_g = atof(argv[2]); gain_b = atof(argv[3]); }
    if (argc >= 7) { exp_r = atof(argv[4]); exp_g = atof(argv[5]); exp_b = atof(argv[6]); }
    struct wl_display *dpy = wl_display_connect(NULL);
    if (!dpy) { fprintf(stderr, "no wayland\n"); return 1; }
    struct wl_registry *reg = wl_display_get_registry(dpy);
    wl_registry_add_listener(reg, &reg_listener, NULL);
    wl_display_roundtrip(dpy);
    if (!gamma_manager) { fprintf(stderr, "compositor has no wlr-gamma-control\n"); return 1; }
    for (struct output *o = outputs; o; o = o->next) {
        o->gamma_control = zwlr_gamma_control_manager_v1_get_gamma_control(gamma_manager, o->wl_output);
        zwlr_gamma_control_v1_add_listener(o->gamma_control, &gamma_listener, o);
    }
    wl_display_roundtrip(dpy);
    fprintf(stderr, "applied R=%.3f G=%.3f B=%.3f (holding)\n", gain_r, gain_g, gain_b);
    while (wl_display_dispatch(dpy) != -1) {}
    return 0;
}
