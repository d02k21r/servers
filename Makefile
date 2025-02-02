install-roles:
	ansible-galaxy install \
		-r "ansible/requirements.yml" \
		--force

rebuild-test-machine:
	vagrant destroy -f && vagrant up

PLAYBOOK := ansible/configuration.yml
STAGE := vagrant

ifeq ($(STAGE), prod)
	ANSIBLE_HOST_KEY_CHECKING := True
	INVENTORY := ansible/hosts_prod
	USER_ARGS := --user="major" --become
else
	ANSIBLE_HOST_KEY_CHECKING := False
	INVENTORY := ansible/hosts_vagrant
	USER_ARGS := --user="root"
endif

ifneq ($(TAGS),)
	TAGS_ARGS := --tags="$(TAGS)"
else
	TAGS_ARGS :=
endif

edit-vars:
	EDITOR=micro \
	ansible-vault edit ansible/vars/vars.yml

configure:
	ANSIBLE_HOST_KEY_CHECKING=$(ANSIBLE_HOST_KEY_CHECKING) \
	ansible-playbook \
		$(USER_ARGS) \
		$(TAGS_ARGS) \
		--inventory="$(INVENTORY)" \
		--extra-vars='ansible_python_interpreter=/usr/bin/python3' \
		$(PLAYBOOK)

configure-prod:
	$(MAKE) configure STAGE="prod"

configure-apps:
	$(MAKE) configure TAGS="webserver,apps,env"

dry-run:
	ANSIBLE_HOST_KEY_CHECKING=$(ANSIBLE_HOST_KEY_CHECKING) \
	ansible-playbook \
		$(USER_ARGS) \
		$(TAGS_ARGS) \
		--inventory="$(INVENTORY)" \
		--extra-vars='ansible_python_interpreter=/usr/bin/python3' \
		--check \
		--diff -vvv \
		$(PLAYBOOK)

list-tags:
	ansible-playbook \
		--inventory="$(INVENTORY)" \
		--list-tags \
		$(PLAYBOOK)

lint:
	ansible-lint "./ansible/configuration.yml" --exclude="./ansible/galaxy.roles/" -v || true
	ansible-lint "./ansible/roles/ssl-certificate/tasks/main.yml" -v || true
