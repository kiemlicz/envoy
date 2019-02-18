import logging
import os

from salt.exceptions import CommandExecutionError

try:
    from kubernetes import client, config
    from kubernetes.client import ApiClient
    from kubernetes.client.rest import ApiException

    HAS_K8S = True
except ImportError:
    HAS_K8S = False


log = logging.getLogger(__name__)


class K8sClient(object):
    def __init__(self, **kwargs):
        if not HAS_K8S:
            raise CommandExecutionError('(unable to import kubernetes, module most likely not installed)')

        self.active_namespace = "default"

        if "KUBERNETES_SERVICE_HOST" in os.environ:
            config.load_incluster_config()
            with open("/var/run/secrets/kubernetes.io/serviceaccount/namespace", "r") as f:
                self.active_namespace = f.read()
        else:
            try:
                # todo handle opts from profile
                config.load_kube_config()
            except FileNotFoundError as e:
                raise CommandExecutionError("unable to create kubernetes config: {}".format(e))

        self.client_apps_v1_api = client.AppsV1Api()
        self.client_core_v1_api = client.CoreV1Api()
        self.client_api = ApiClient()

    def read(self, kind, name=None, namespace=None):
        if not namespace:
            namespace = self.active_namespace
        method = "read_namespaced_{}".format(kind)
        try:
            c = self._client(kind)
            result = getattr(c, method)(name=name, namespace=namespace)
            return self.client_api.sanitize_for_serialization(result)
        except AttributeError as e:
            log.exception(e)
            raise CommandExecutionError("Method {} not found".format(method))
        except ApiException as e:
            log.error("unable to fetch: {}".format(kind))
            log.exception(e)
            return None

    def list(self, kind, label_selector=None, namespace=None):
        if not namespace:
            namespace = self.active_namespace
        method = "list_namespaced_{}".format(kind)
        try:
            c = self._client(kind)
            result = getattr(c, method)(namespace=namespace, label_selector=label_selector)
            return self.client_api.sanitize_for_serialization(result)
        except AttributeError as e:
            log.exception(e)
            raise CommandExecutionError("Method {} not found".format(method))
        except ApiException as e:
            log.error("unable to fetch: {}".format(kind))
            log.exception(e)
            return None

    def _client(self, kind):
        if kind == "pod":
            return self.client_core_v1_api
        else:
            return self.client_apps_v1_api


def k8s_client(**kwargs):
    log.info("Creating K8s client")
    return K8sClient(**kwargs)
