local IMAGE_NAME = 'rspamd/rbldnsd';
local DEBIAN_VERSION = 'bookworm';

local docker_defaults = {
  username: {
    from_secret: 'docker_username',
  },
  password: {
    from_secret: 'docker_password',
  },
};

local pipeline_defaults = {
  kind: 'pipeline',
  type: 'docker',
};

local trigger = {
  trigger: {
    branch: [
      'main',
    ],
    event: [
      'push',
      'custom',
    ],
  },
};

local platform(arch) = {
  platform: {
    os: 'linux',
    arch: arch,
  },
};

local make_build_image(arch) = {
  name: 'build_image_' + arch,
  steps: [
    {
      name: 'build_image',
      image: 'plugins/docker',
      settings: {
        dockerfile: 'Dockerfile.build',
        label_schema: [
          'docker.dockerfile=Dockerfile.build',
        ],
        build_args: [
          'DEBIAN_VERSION=' + DEBIAN_VERSION,
        ],
        repo: IMAGE_NAME,
        tags: [
          'build-' + arch,
        ],
      } + docker_defaults,
    },
  ],
} + platform(arch) + trigger + pipeline_defaults;

local signature_placeholder = {
  kind: 'signature',
  hmac: '0000000000000000000000000000000000000000000000000000000000000000',
};

local make_multiarch_build_image = {
  local image_tag = 'build',
  name: 'multiarch_image',
  depends_on: [
    'build_image_amd64',
    'build_image_arm64',
  ],
  steps: [
    {
      name: 'multiarch_image',
      image: 'plugins/manifest',
      settings: {
        target: std.format('%s:%s', [IMAGE_NAME, image_tag]),
        template: std.format('%s:%s-ARCH', [IMAGE_NAME, image_tag]),
        platforms: [
          'linux/amd64',
          'linux/arm64',
        ],
      } + docker_defaults,
    },
  ],
} + trigger + pipeline_defaults;

[
  make_build_image('amd64'),
  make_build_image('arm64'),
  make_multiarch_build_image,
  signature_placeholder,
]
